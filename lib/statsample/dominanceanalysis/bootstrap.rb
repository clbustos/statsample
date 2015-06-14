module Statsample
  class DominanceAnalysis
    # == Goal
    # Generates Bootstrap sample to identity the replicability of a Dominance Analysis. See Azen & Bodescu (2003) for more information.
    #
    # == Usage
    # 
    # require 'statsample'
    # a = Daru::Vector.new(100.times.collect {rand})
    # b = Daru::Vector.new(100.times.collect {rand})
    # c = Daru::Vector.new(100.times.collect {rand})
    # d = Daru::Vector.new(100.times.collect {rand})
    # ds = Daru::DataFrame.new({:a => a,:b => b,:c => c,:d => d})
    # ds[:y] = ds.collect_rows { |row| row[:a]*5+row[:b]*2+row[:c]*2+row[:d]*2+10*rand() }
    # dab=Statsample::DominanceAnalysis::Bootstrap.new(ds, :y, :debug=>true)
    # dab.bootstrap(100,nil)
    # puts dab.summary
    # <strong>Output</strong>
    #   Sample size: 100
    #  t: 1.98421693632958
    #  
    #  Linear Regression Engine: Statsample::Regression::Multiple::MatrixEngine
    #  Table: Bootstrap report
    #  --------------------------------------------------------------------------------------------
    #  | pairs                 | sD  | Dij    | SE(Dij) | Pij   | Pji   | Pno   | Reproducibility |
    #  --------------------------------------------------------------------------------------------
    #  | Complete dominance    |
    #  --------------------------------------------------------------------------------------------
    #  | a - b                 | 1.0 | 0.6150 | 0.454   | 0.550 | 0.320 | 0.130 | 0.550           |
    #  | a - c                 | 1.0 | 0.9550 | 0.175   | 0.930 | 0.020 | 0.050 | 0.930           |
    #  | a - d                 | 1.0 | 0.9750 | 0.131   | 0.960 | 0.010 | 0.030 | 0.960           |
    #  | b - c                 | 1.0 | 0.8800 | 0.276   | 0.820 | 0.060 | 0.120 | 0.820           |
    #  | b - d                 | 1.0 | 0.9250 | 0.193   | 0.860 | 0.010 | 0.130 | 0.860           |
    #  | c - d                 | 0.5 | 0.5950 | 0.346   | 0.350 | 0.160 | 0.490 | 0.490           |
    #  --------------------------------------------------------------------------------------------
    #  | Conditional dominance |
    #  --------------------------------------------------------------------------------------------
    #  | a - b                 | 1.0 | 0.6300 | 0.458   | 0.580 | 0.320 | 0.100 | 0.580           |
    #  | a - c                 | 1.0 | 0.9700 | 0.156   | 0.960 | 0.020 | 0.020 | 0.960           |
    #  | a - d                 | 1.0 | 0.9800 | 0.121   | 0.970 | 0.010 | 0.020 | 0.970           |
    #  | b - c                 | 1.0 | 0.8850 | 0.283   | 0.840 | 0.070 | 0.090 | 0.840           |
    #  | b - d                 | 1.0 | 0.9500 | 0.181   | 0.920 | 0.020 | 0.060 | 0.920           |
    #  | c - d                 | 0.5 | 0.5800 | 0.360   | 0.350 | 0.190 | 0.460 | 0.460           |
    #  --------------------------------------------------------------------------------------------
    #  | General Dominance     |
    #  --------------------------------------------------------------------------------------------
    #  | a - b                 | 1.0 | 0.6500 | 0.479   | 0.650 | 0.350 | 0.000 | 0.650           |
    #  | a - c                 | 1.0 | 0.9800 | 0.141   | 0.980 | 0.020 | 0.000 | 0.980           |
    #  | a - d                 | 1.0 | 0.9900 | 0.100   | 0.990 | 0.010 | 0.000 | 0.990           |
    #  | b - c                 | 1.0 | 0.9000 | 0.302   | 0.900 | 0.100 | 0.000 | 0.900           |
    #  | b - d                 | 1.0 | 0.9700 | 0.171   | 0.970 | 0.030 | 0.000 | 0.970           |
    #  | c - d                 | 1.0 | 0.5600 | 0.499   | 0.560 | 0.440 | 0.000 | 0.560           |
    #  --------------------------------------------------------------------------------------------
    #  
    #  Table: General averages
    #  ---------------------------------------
    #  | var | mean  | se    | p.5   | p.95  |
    #  ---------------------------------------
    #  | a   | 0.133 | 0.049 | 0.062 | 0.218 |
    #  | b   | 0.106 | 0.048 | 0.029 | 0.199 |
    #  | c   | 0.035 | 0.032 | 0.002 | 0.106 |
    #  | d   | 0.023 | 0.019 | 0.002 | 0.062 |
    #  ---------------------------------------
    #
    # == References:
    # * Azen, R. & Budescu, D.V. (2003). The dominance analysis approach for comparing predictors in multiple regression. <em>Psychological Methods, 8</em>(2), 129-148.
    class Bootstrap
      include Writable
      include Summarizable
      # Total Dominance results
      attr_reader :samples_td
      # Conditional Dominance results
      attr_reader :samples_cd
      # General Dominance results
      attr_reader :samples_gd
      # General average results 
      attr_reader :samples_ga
      # Name of fields
      attr_reader :fields
      # Regression class used for analysis
      attr_accessor :regression_class
      # Dataset
      attr_accessor :ds
      # Name of analysis
      attr_accessor :name
      # Alpha level of confidence. Default: ALPHA
      attr_accessor :alpha
      # Debug?
      attr_accessor :debug
      # Default level of confidence for t calculation
      ALPHA=0.95
      # Create a new Dominance Analysis Bootstrap Object
      # 
      # * ds: A Daru::DataFrame object
      # * y_var: Name of dependent variable
      # * opts: Any other attribute of the class 
      def initialize(ds,y_var, opts=Hash.new)
        @ds    = ds
        @y_var = y_var.respond_to?(:to_sym) ? y_var.to_sym : y_var
        @n     = ds.nrows
        
        @n_samples=0
        @alpha=ALPHA
        @debug=false
        if y_var.is_a? Array
          @fields=ds.vectors.to_a - y_var
          @regression_class=Regression::Multiple::MultipleDependent
          
        else
          @fields=ds.vectors.to_a - [y_var]
          @regression_class=Regression::Multiple::MatrixEngine
        end
        @samples_ga=@fields.inject({}) { |a,v| a[v]=[]; a }

        @name=_("Bootstrap dominance Analysis:  %s over %s") % [ ds.vectors.to_a.join(",") , @y_var]
        opts.each{|k,v|
          self.send("#{k}=",v) if self.respond_to? k
        }
        create_samples_pairs            
      end
      # lr_class deprecated
      alias_method :lr_class, :regression_class
      def da
        if @da.nil?
          @da=DominanceAnalysis.new(@ds,@y_var, :regression_class => @regression_class)
        end
        @da
      end
      # Creates n re-samples from original dataset and store result of
      # each sample on @samples_td, @samples_cd, @samples_gd, @samples_ga
      # 
      # * number_samples: Number of new samples to add
      # * n: size of each new sample. If nil, equal to original sample size     
      def bootstrap(number_samples,n=nil)
        number_samples.times{ |t|
          @n_samples+=1
          puts _("Bootstrap %d of %d") % [t+1, number_samples] if @debug
          ds_boot=@ds.bootstrap(n)                 
          da_1=DominanceAnalysis.new(ds_boot, @y_var, :regression_class => @regression_class)

          da_1.total_dominance.each{|k,v|
            @samples_td[k].push(v)
          }
          da_1.conditional_dominance.each{|k,v|
            @samples_cd[k].push(v)
          }
          da_1.general_dominance.each{|k,v|
            @samples_gd[k].push(v)
          }
          da_1.general_averages.each{|k,v|
            @samples_ga[k].push(v)
          }
        }
      end
      def create_samples_pairs
        @samples_td={}
        @samples_cd={}
        @samples_gd={}
        @pairs=[]
        c=(0...@fields.size).to_a.combination(2)
        c.each do |data|
          p data
          convert=data.collect {|i| @fields[i] }
          @pairs.push(convert)
          [@samples_td, @samples_cd, @samples_gd].each{|s|
            s[convert]=[]
          }
        end
      end
      def t
        Distribution::T.p_value(1-((1-@alpha) / 2), @n_samples - 1)
      end
      def report_building(builder) # :nodoc:
        raise "You should bootstrap first" if @n_samples==0
        builder.section(:name=>@name) do |generator|
          generator.text _("Sample size: %d\n") % @n_samples
          generator.text "t: #{t}\n"
          generator.text _("Linear Regression Engine: %s") % @regression_class.name
          
          table=ReportBuilder::Table.new(:name=>"Bootstrap report", :header => [_("pairs"), "sD","Dij", _("SE(Dij)"), "Pij", "Pji", "Pno", _("Reproducibility")])
          table.row([_("Complete dominance"),"","","","","","",""])
          table.hr
          @pairs.each{|pair|
            std=Daru::Vector.new(@samples_td[pair])
            ttd=da.total_dominance_pairwise(pair[0],pair[1])
            table.row(summary_pairs(pair,std,ttd))
          }
          table.hr
          table.row([_("Conditional dominance"),"","","","","","",""])
          table.hr
          @pairs.each{|pair|
            std=Daru::Vector.new(@samples_cd[pair])
            ttd=da.conditional_dominance_pairwise(pair[0],pair[1])
            table.row(summary_pairs(pair,std,ttd))
          
          }
          table.hr
          table.row([_("General Dominance"),"","","","","","",""])
          table.hr
          @pairs.each{|pair|
            std=Daru::Vector.new(@samples_gd[pair])
            ttd=da.general_dominance_pairwise(pair[0],pair[1])
            table.row(summary_pairs(pair,std,ttd))
          }
          generator.parse_element(table)
          
          table=ReportBuilder::Table.new(:name=>_("General averages"), :header=>[_("var"), _("mean"), _("se"), _("p.5"), _("p.95")])
          
          @fields.each{|f|
            v=Daru::Vector.new(@samples_ga[f])
            row=[@ds[f].name, sprintf("%0.3f",v.mean), sprintf("%0.3f",v.sd), sprintf("%0.3f",v.percentil(5)),sprintf("%0.3f",v.percentil(95))]
            table.row(row)          
          }
          
          generator.parse_element(table)
        end
      end
      def summary_pairs(pair,std,ttd)
          freqs=std.proportions
          [0, 0.5, 1].each{|n|
              freqs[n]=0 if freqs[n].nil?
          }
          name="%s - %s" % [@ds[pair[0]].name, @ds[pair[1]].name]
          [name,f(ttd,1),f(std.mean,4),f(std.sd),f(freqs[1]), f(freqs[0]), f(freqs[0.5]), f(freqs[ttd])]
      end
      def f(v,n=3)
          prec="%0.#{n}f"
          sprintf(prec,v)
      end
    end
  end
end
