module Statsample
  # Dominance Analysis is a procedure based on an examination of the R<sup>2</sup> values
  # for all possible subset models, to identify the relevance of one or more 
  # predictors in the prediction of criterium.
  #
  # See Budescu(1993), Azen & Budescu (2003, 2006) for more information.
  #
  # == Use
  #
  # a = Daru::Vector.new(1000.times.collect {rand})
  # b = Daru::Vector.new(1000.times.collect {rand})
  # c = Daru::Vector.new(1000.times.collect {rand})
  # ds= Daru::DataFrame.new({:a => a,:b => b,:c => c})
  # ds[:y] = ds.collect_rows {|row| row[:a]*5 + row[:b]*3 + row[:c]*2 + rand()}
  # da=Statsample::DominanceAnalysis.new(ds, :y)
  # puts da.summary
  # 
  # === Output:
  #
  #  Report: Report 2010-02-08 19:10:11 -0300
  #  Table: Dominance Analysis result
  #  ------------------------------------------------------------
  #  |                  | r2    | sign  | a     | b     | c     |
  #  ------------------------------------------------------------
  #  | Model 0          |       |       | 0.648 | 0.265 | 0.109 |
  #  ------------------------------------------------------------
  #  | a                | 0.648 | 0.000 | --    | 0.229 | 0.104 |
  #  | b                | 0.265 | 0.000 | 0.612 | --    | 0.104 |
  #  | c                | 0.109 | 0.000 | 0.643 | 0.260 | --    |
  #  ------------------------------------------------------------
  #  | k=1 Average      |       |       | 0.627 | 0.244 | 0.104 |
  #  ------------------------------------------------------------
  #  | a*b              | 0.877 | 0.000 | --    | --    | 0.099 |
  #  | a*c              | 0.752 | 0.000 | --    | 0.224 | --    |
  #  | b*c              | 0.369 | 0.000 | 0.607 | --    | --    |
  #  ------------------------------------------------------------
  #  | k=2 Average      |       |       | 0.607 | 0.224 | 0.099 |
  #  ------------------------------------------------------------
  #  | a*b*c            | 0.976 | 0.000 | --    | --    | --    |
  #  ------------------------------------------------------------
  #  | Overall averages |       |       | 0.628 | 0.245 | 0.104 |
  #  ------------------------------------------------------------
  #  
  #  Table: Pairwise dominance
  #  -----------------------------------------
  #  | Pairs | Total | Conditional | General |
  #  -----------------------------------------
  #  | a - b | 1.0   | 1.0         | 1.0     |
  #  | a - c | 1.0   | 1.0         | 1.0     |
  #  | b - c | 1.0   | 1.0         | 1.0     |
  #  -----------------------------------------
  #
  # == Reference:
  # * Budescu, D. V. (1993). Dominance analysis: a new approach to the problem of relative importance of predictors in multiple regression. <em>Psychological Bulletin, 114</em>, 542-551.
  # * Azen, R. & Budescu, D.V. (2003). The dominance analysis approach for comparing predictors in multiple regression. <em>Psychological Methods, 8</em>(2), 129-148.
  # * Azen, R. & Budescu, D.V. (2006). Comparing predictors in Multivariate Regression Models: An extension of Dominance Analysis. <em>Journal of Educational and Behavioral Statistics, 31</em>(2), 157-180.
  #
  class DominanceAnalysis
    include Summarizable
    # Class to generate the regressions. Default to Statsample::Regression::Multiple::MatrixEngine
    attr_accessor :regression_class
    # Name of analysis
    attr_accessor :name
    # Set to true if you want to build from dataset, not correlation matrix
    attr_accessor :build_from_dataset
    #  Array with independent variables. You could create subarrays, 
    #  to test groups of predictors as blocks
    attr_accessor  :predictors
    # If you provide a matrix as input, you should set 
    # the number of cases to define significance of R^2
    attr_accessor  :cases
    # Method of :regression_class used to measure association. 
    # 
    # Only necessary to change if you have multivariate dependent.
    # * :r2yx (R^2_yx), the default option, is the  option when distinction
    #   between independent and dependents variable is arbitrary
    # * :p2yx is the option when the distinction between independent and dependents variables is real.
    #   
    
    attr_accessor  :method_association
    
    
    attr_reader :dependent
    
    UNIVARIATE_REGRESSION_CLASS=Statsample::Regression::Multiple::MatrixEngine
    MULTIVARIATE_REGRESSION_CLASS=Statsample::Regression::Multiple::MultipleDependent
    
    def self.predictor_name(variable)
      if variable.is_a? Array
        sprintf("(%s)", variable.join(","))
      else
        variable
      end
    end
    # Creates a new DominanceAnalysis object
    # Parameters:
    # * input:    A Matrix or Dataset object
    # * dependent: Name of dependent variable. Could be an array, if you want to
    #             do an Multivariate Regression Analysis. If nil, set to all
    #             fields on input, except criteria
 
    def initialize(input, dependent, opts=Hash.new)
      @build_from_dataset=false
      if dependent.is_a? Array
        @regression_class= MULTIVARIATE_REGRESSION_CLASS
        @method_association=:r2yx
      else
        @regression_class= UNIVARIATE_REGRESSION_CLASS
        @method_association=:r2
      end
      
      @name=nil
      opts.each{|k,v|
        self.send("#{k}=",v) if self.respond_to? k
      }
      @dependent=dependent
      @dependent=[@dependent] unless @dependent.is_a? Array

      if input.kind_of? Daru::DataFrame
        @predictors ||= input.vectors.to_a - @dependent
        @ds=input
        @matrix=Statsample::Bivariate.correlation_matrix(input)
        @cases=Statsample::Bivariate.min_n_valid(input)
      elsif input.is_a? ::Matrix
        @predictors ||= input.fields-@dependent
        @ds=nil
        @matrix=input
      else
        raise ArgumentError.new("You should use a Matrix or a Dataset")
      end

      @name=_("Dominance Analysis:  %s over %s") % [ @predictors.flatten.join(",") , @dependent.join(",")] if @name.nil?
      @models=nil
      @models_data=nil
      @general_averages=nil
    end
    # Compute models. 
    def compute
      create_models
      fill_models
    end
    def models
      if @models.nil?
        compute
      end
      @models
    end
    
    def models_data
      if @models_data.nil?
        compute
      end
      @models_data
    end
    def create_models
      @models=[]
      @models_data={}
      for i in 1..@predictors.size
        c=(0...@predictors.size).to_a.combination(i)
        c.each  do |data|
          
          independent=data.collect {|i1| @predictors[i1] }
          @models.push(independent)
          if (@build_from_dataset)
            data=@ds.dup(independent.flatten+@dependent)
          else
            data=@matrix.submatrix(independent.flatten+@dependent)
          end
          
          modeldata=ModelData.new(independent, data, self)
          models_data[independent.sort {|a,b| a.to_s<=>b.to_s}]=modeldata
        end
      end
    end
    def fill_models
      @models.each do |m|
        @predictors.each do |f|
          next if m.include? f
          base_model=md(m)
          comp_model=md(m+[f])
          base_model.add_contribution(f,comp_model.r2)
        end
      end
    end
    private :create_models, :fill_models
    
    def dominance_for_nil_model(i,j)
      if md([i]).r2>md([j]).r2
        1
      elsif md([i]).r2<md([j]).r2
        0
      else
        0.5
      end           
    end
    # Returns 1 if i D k, 0 if j dominates i and 0.5 if undetermined
    def total_dominance_pairwise(i,j)
      dm=dominance_for_nil_model(i,j)
      return 0.5 if dm==0.5
      dominances=[dm]
      models_data.each do |k,m|
        if !m.contributions[i].nil? and !m.contributions[j].nil?
          if m.contributions[i]>m.contributions[j]
              dominances.push(1)
          elsif m.contributions[i]<m.contributions[j]
              dominances.push(0)
          else
            return 0.5
              #dominances.push(0.5)
          end
        end
      end
      final=dominances.uniq
      final.size>1 ? 0.5 : final[0]
    end
    
    # Returns 1 if i cD k, 0 if j cD i and 0.5 if undetermined
    def conditional_dominance_pairwise(i,j)
      dm=dominance_for_nil_model(i,j)
      return 0.5 if dm==0.5
      dominances=[dm]
      for k in 1...@predictors.size
        a=average_k(k)
        if a[i]>a[j]
            dominances.push(1)
        elsif a[i]<a[j]
            dominances.push(0)
        else
          return 0.5
            #dominances.push(0.5)
        end                 
      end
      final=dominances.uniq
      final.size>1 ? 0.5 : final[0]            
    end
    # Returns 1 if i gD k, 0 if j gD i and 0.5 if undetermined        
    def general_dominance_pairwise(i,j)
      ga=general_averages
      if ga[i]>ga[j]
        1
      elsif ga[i]<ga[j]
        0
      else
        0.5
      end                 
    end
    def pairs
      models.find_all{|m| m.size==2}
    end
    def total_dominance
      pairs.inject({}){|a,pair| a[pair]=total_dominance_pairwise(pair[0], pair[1])
      a
      }
    end
    def conditional_dominance
      pairs.inject({}){|a,pair| a[pair]=conditional_dominance_pairwise(pair[0], pair[1])
      a
      }
    end
    def general_dominance
      pairs.inject({}){|a,pair| a[pair]=general_dominance_pairwise(pair[0], pair[1])
      a
      }
    end
    
    def md(m)
      models_data[m.sort {|a,b| a.to_s <=> b.to_s}]
    end
    # Get all model of size k
    def md_k(k)
      out=[]
      @models.each{ |m| out.push(md(m)) if m.size==k }
      out
    end
    
    # For a hash with arrays of numbers as values
    # Returns a hash with same keys and 
    # value as the mean of values of original hash
    def get_averages(averages)
      out={}
      averages.each{ |key,val| out[key] = Daru::Vector.new(val).mean }
      out
    end
    # Hash with average for each k size model.
    def average_k(k)
      return nil if k==@predictors.size
      models=md_k(k)
      averages=@predictors.inject({}) {|a,v| a[v]=[];a}
      models.each do |m|
        @predictors.each do |f|
          averages[f].push(m.contributions[f]) unless m.contributions[f].nil?
        end
      end
      get_averages(averages)
    end
    def general_averages
      if @general_averages.nil?
        averages=@predictors.inject({}) {|a,v| a[v]=[md([v]).r2];a}
        for k in 1...@predictors.size
          ak=average_k(k)
          @predictors.each do |f|
            averages[f].push(ak[f])
          end
        end
        @general_averages=get_averages(averages)
      end
      @general_averages
    end
    

    def report_building(g)
      compute if @models.nil?
      g.section(:name=>@name) do |generator|
        header=["","r2",_("sign")]+@predictors.collect {|c| DominanceAnalysis.predictor_name(c) }
        
        generator.table(:name=>_("Dominance Analysis result"), :header=>header) do |t|
          row=[_("Model 0"),"",""]+@predictors.collect{|f|
            sprintf("%0.3f",md([f]).r2)
          }
          
          t.row(row)
          t.hr
          for i in 1..@predictors.size
            mk=md_k(i)
            mk.each{|m|
              t.row(m.add_table_row)
            }
            # Report averages
            a=average_k(i)
            if !a.nil?
                t.hr
                row=[_("k=%d Average") % i,"",""] + @predictors.collect{|f|
                    sprintf("%0.3f",a[f])
                }
                t.row(row)
                t.hr
                
            end
          end
          
          g=general_averages
          t.hr
          
          row=[_("Overall averages"),"",""]+@predictors.collect{|f|
                    sprintf("%0.3f",g[f])
          }
          t.row(row)
        end
        
        td=total_dominance
        cd=conditional_dominance
        gd=general_dominance
        generator.table(:name=>_("Pairwise dominance"), :header=>[_("Pairs"),_("Total"),_("Conditional"),_("General")]) do |t|
          pairs.each{|pair|
            name=pair.map{|v| v.is_a?(Array) ? "("+v.join("-")+")" : v}.join(" - ")
            row=[name, sprintf("%0.1f",td[pair]), sprintf("%0.1f",cd[pair]), sprintf("%0.1f",gd[pair])]
            t.row(row)
          }
        end
      end
    end
    class ModelData # :nodoc:
      attr_reader :contributions
      def initialize(independent, data, da)
        @independent=independent
        @data=data
        @predictors=da.predictors
        @dependent=da.dependent
        @cases=da.cases
        @method=da.method_association
        @contributions=@independent.inject({}){|a,v| a[v]=nil;a}
        
        r_class=da.regression_class
        
        if @dependent.size==1
          @lr=r_class.new(data, @dependent[0], :cases=>@cases)
        else
          @lr=r_class.new(data, @dependent, :cases=>@cases)
        end
      end
      def add_contribution(f, v)
        @contributions[f]=v-r2
      end
      def r2
        @lr.send(@method)
      end
      def name
        @independent.collect {|variable|
          DominanceAnalysis.predictor_name(variable)
        }.join("*")
      end
      def add_table_row
        if @cases
          sign=sprintf("%0.3f", @lr.probability)
		else
		sign="???"
        end
      
        [name, sprintf("%0.3f",r2), sign] + @predictors.collect{|k|
          v=@contributions[k]
          if v.nil?
              "--"
          else
          sprintf("%0.3f",v)
          end
        }
      end
      def summary
        out=sprintf("%s: r2=%0.3f(p=%0.2f)\n",name, r2, @lr.significance, @lr.sst)
        out << @predictors.collect{|k|
          v=@contributions[k]
          if v.nil?
              "--"
          else
            sprintf("%s=%0.3f",k,v)
          end
        }.join(" | ") 
        out << "\n"
        return out
      end
    end # end ModelData
  end # end Dominance Analysis
end

require 'statsample/dominanceanalysis/bootstrap'
