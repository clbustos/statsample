module Statsample
  class DominanceAnalysis
    # Generates Bootstrap sample to identity the replicability of a Dominance Analysis. See Azen & Bodescu (2003) for more information.
    # References: 
    # * Azen, R. & Budescu, D.V. (2003). The dominance analysis approach for comparing predictors in multiple regression. _Psychological Methods, 8_(2), 129-148.
    class Bootstrap
      include GetText
      include Writable
      bindtextdomain("statsample")
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
      # Create a new Dominance Analysis Bootstrap Object
      # 
      # * ds: A Dataset object
      # * y_var: Name of dependent variable
      # * opts: Any other attribute of the class 
      ALPHA=0.95
      def initialize(ds,y_var, opts=Hash.new)
        @ds=ds
        @y_var=y_var
        @n=ds.cases
        
        @n_samples=0
        @alpha=ALPHA
        @debug=false
        if y_var.is_a? Array
          @fields=ds.fields-y_var
          @regression_class=Regression::Multiple::MultipleDependent
          
        else
          @fields=ds.fields-[y_var]
          @regression_class=Regression::Multiple::MatrixEngine
        end
        @samples_ga=@fields.inject({}){|a,v| a[v]=[];a}

        @name=_("Bootstrap dominance Analysis:  %s over %s") % [ ds.fields.join(",") , @y_var]
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
        c=Statsample::Combination.new(2,@fields.size)
        c.each do |data|
          convert=data.collect {|i| @fields[i] }
          @pairs.push(convert)
          [@samples_td, @samples_cd, @samples_gd].each{|s|
            s[convert]=[]
          }
        end
      end
      # Summary of analysis
      def summary
        rp=ReportBuilder.new()
        rp.add(self)
        rp.to_text
      end
      def t
        Distribution::T.p_value(1-((1-@alpha) / 2), @n_samples - 1)
      end
      def to_reportbuilder(generator) # :nodoc:
        raise "You should bootstrap first" if @n_samples==0
        anchor=generator.add_toc_entry(_("DAB: ")+@name)
        generator.add_html "<div class='dominance-analysis-bootstrap'>#{@name}<a name='#{anchor}'></a>"
        
        generator.add_text _("Sample size: %d\n") % @n_samples
        generator.add_text "t: #{t}\n"
        generator.add_text _("Linear Regression Engine: %s") % @regression_class.name
        
        table=ReportBuilder::Table.new(:name=>"Bootstrap report", :header => [_("pairs"), "sD","Dij", _("SE(Dij)"), "Pij", "Pji", "Pno", _("Reproducibility")])
        table.add_row([_("Complete dominance")])
        table.add_horizontal_line
        @pairs.each{|pair|
          std=@samples_td[pair].to_vector(:scale)
          ttd=da.total_dominance_pairwise(pair[0],pair[1])
          table.add_row(summary_pairs(pair,std,ttd))
        }
        table.add_horizontal_line
        table.add_row([_("Conditional dominance")])
        table.add_horizontal_line
        @pairs.each{|pair|
          std=@samples_cd[pair].to_vector(:scale)
          ttd=da.conditional_dominance_pairwise(pair[0],pair[1])
          table.add_row(summary_pairs(pair,std,ttd))
        
        }
        table.add_horizontal_line
        table.add_row([_("General Dominance")])
        table.add_horizontal_line
        @pairs.each{|pair|
          std=@samples_gd[pair].to_vector(:scale)
          ttd=da.general_dominance_pairwise(pair[0],pair[1])
          table.add_row(summary_pairs(pair,std,ttd))
        }
        generator.parse_element(table)
        
        table=ReportBuilder::Table.new(:name=>_("General averages"), :header=>[_("var"), _("mean"), _("se"), _("p.5"), _("p.95")])
        
        @fields.each{|f|
          v=@samples_ga[f].to_vector(:scale)
          row=[@ds.label(f), sprintf("%0.3f",v.mean), sprintf("%0.3f",v.sd), sprintf("%0.3f",v.percentil(5)),sprintf("%0.3f",v.percentil(95))]
          table.add_row(row)
        
        }
        
        generator.parse_element(table)
        generator.add_html("</div>")
      end
      def summary_pairs(pair,std,ttd)
          freqs=std.proportions
          [0, 0.5, 1].each{|n|
              freqs[n]=0 if freqs[n].nil?
          }
          name=@ds.label(pair[0])+" - "+@ds.label(pair[1])
          [name,f(ttd,1),f(std.mean,4),f(std.sd),f(freqs[1]), f(freqs[0]), f(freqs[0.5]), f(freqs[ttd])]
      end
      def f(v,n=3)
          prec="%0.#{n}f"
          sprintf(prec,v)
      end
    end
  end
end
