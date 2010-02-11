require 'statsample/dominanceanalysis/bootstrap'
module Statsample
  # Dominance Analysis is a procedure based on an examination of the R^2 values
  # for all possible subset models, to identify the relevance of one or more 
  # predictors in the prediction of criterium.
  #
  # See Budescu(1993) and Azen & Budescu (2003) for more information.
  #
  # Example: 
  #
  #  a=1000.times.collect {rand}.to_scale
  #  b=1000.times.collect {rand}.to_scale
  #  c=1000.times.collect {rand}.to_scale
  #  ds={'a'=>a,'b'=>b,'c'=>c}.to_dataset
  #  ds['y']=ds.collect{|row| row['a']*5+row['b']*3+row['c']*2+rand()}
  #  da=Statsample::DominanceAnalysis.new(ds,'y')
  #  puts da.summary
  # 
  # Output:
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
  # == References:
  # * Budescu, D. V. (1993). Dominance analysis: a new approach to the problem of relative importance of predictors in multiple regression. _Psychological Bulletin, 114_, 542-551.
  # * Azen, R. & Budescu, D.V. (2003). The dominance analysis approach for comparing predictors in multiple regression. _Psychological Methods, 8_(2), 129-148.
  class DominanceAnalysis
    include GetText
    bindtextdomain("statsample")
    # Class to generate the regressions. Default to Statsample::Regression::Multiple::RubyEngine
    attr_accessor :regression_class
    # Name of analysis
    attr_accessor :name
    
    # Creates a new DominanceAnalysis object
    # Params:
    # * ds: A Dataset object
    # * y_var: Name of dependent variable
    # * opts: Any other attribute of the class 
    # 
    def initialize(ds,y_var, opts=Hash.new)
      @y_var=y_var
      @dy=ds[@y_var]
      @ds=ds
      @ds_indep=ds.dup(ds.fields-[y_var])
      @fields=@ds_indep.fields
      @regression_class=Statsample::Regression::Multiple::RubyEngine
      @name=_("Dominance Analysis:  %s over %s") % [ ds.fields.join(",") , @y_var]
      opts.each{|k,v|
        self.send("#{k}=",v) if self.respond_to? k
      }
      create_models
      fill_models
    end
    def fill_models
      @models.each do |m|
        @fields.each do |f|
          next if m.include? f
          base_model=md(m)
          comp_model=md(m+[f])
          base_model.add_contribution(f,comp_model.r2)
        end
      end
    end
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
      @models_data.each do |k,m|
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
      for k in 1...@fields.size
        a=average_k(k)
        if a[i]>a[j]
            dominances.push(1)
        elsif a[i]<a[j]
            dominances.push(0)
        else
          return 0.5
            dominances.push(0.5)
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
      @models.find_all{|m| m.size==2}
    end
    def total_dominance
      pairs.inject({}){|a,pair| a[pair]=total_dominance_pairwise(pair[0], pair[1])
      a
      }
    end
    def conditional_dominance
      pairs.inject({}){|a,pair|
      a[pair]=conditional_dominance_pairwise(pair[0], pair[1])
      a
      }
    end
    def general_dominance
      pairs.inject({}){|a,pair|
      a[pair]=general_dominance_pairwise(pair[0], pair[1])
      a
      }
    end
    
    def md(m)
      @models_data[m.sort]
    end
    # Get all model of size k
    def md_k(k)
      out=[]
      models=@models.each{|m| out.push(md(m)) if m.size==k }
      out
    end
    
    # For a hash with arrays of numbers as values
    # Returns a hash with same keys and 
    # value as the mean of values of original hash
    
    def get_averages(averages)
      out={}
      averages.each{|key,val| out[key]=val.to_vector(:scale).mean }
      out
    end
    # Hash with average for each k size model.
    def average_k(k)
      return nil if k==@fields.size
      models=md_k(k)
      averages=@fields.inject({}) {|a,v| a[v]=[];a}
      models.each do |m|
        @fields.each do |f|
          averages[f].push(m.contributions[f]) unless m.contributions[f].nil?
        end
      end
      get_averages(averages)
    end
    def general_averages
      if @general_averages.nil?
        averages=@fields.inject({}) {|a,v| a[v]=[md([v]).r2];a}
        for k in 1...@fields.size
          ak=average_k(k)
          @fields.each do |f|
            averages[f].push(ak[f])
          end
        end
        @general_averages=get_averages(averages)
      end
      @general_averages
    end
    def create_models
      @models=[]
      @models_data={}
      for i in 1..@fields.size
      c=Statsample::Combination.new(i,@fields.size)
      c.each  do |data|
        convert=data.collect {|i1| @fields[i1] }
        @models.push(convert)
        ds_prev=@ds.dup(convert+[@y_var])
        modeldata=ModelData.new(convert,ds_prev, @y_var, @fields, @regression_class)
        @models_data[convert.sort]=modeldata
      end
      end
    end
    def summary
      rp=ReportBuilder.new()
      rp.add(self)
      rp.to_text
    end
    def to_reportbuilder(generator)
      anchor=generator.add_toc_entry(_("DA: ")+@name)
      generator.add_html "<div class='dominance-analysis'>#{@name}<a name='#{anchor}'></a>"
      t=ReportBuilder::Table.new(:name=>_("Dominance Analysis result"))
      t.header=["","r2",_("sign")]+@fields
      row=[_("Model 0"),"",""]+@fields.collect{|f|
        sprintf("%0.3f", md([f]).r2)
      }
      t.add_row(row)
      t.add_horizontal_line
      for i in 1..@fields.size
        mk=md_k(i)
        mk.each{|m|
          t.add_row(m.add_table_row)
        }
        # Report averages
        a=average_k(i)
        if !a.nil?
            t.add_horizontal_line
            row=[_("k=%d Average") % i,"",""] + @fields.collect{|f|
                sprintf("%0.3f",a[f])
            }
            t.add_row(row)
            t.add_horizontal_line
            
        end
        
      end
      
      g=general_averages
      t.add_horizontal_line
      
      row=[_("Overall averages"),"",""]+@fields.collect{|f|
                sprintf("%0.3f",g[f])
      }
      t.add_row(row)
      generator.parse_element(t)
      
      td=total_dominance
      cd=conditional_dominance
      gd=general_dominance
      t=ReportBuilder::Table.new(:name=>_("Pairwise dominance"), :header=>[_("Pairs"),_("Total"),_("Conditional"),_("General")])
      pairs.each{|p|
        name=p.join(" - ")
        row=[name, sprintf("%0.1f",td[p]), sprintf("%0.1f",cd[p]), sprintf("%0.1f",gd[p])]
        t.add_row(row)
      }
      generator.parse_element(t)
      generator.add_html("</div>")
    end
    class ModelData
      attr_reader :contributions
      def initialize(name,ds,y_var,fields,r_class)
        @name=name
        @fields=fields
        @contributions=@fields.inject({}){|a,v| a[v]=nil;a}
        r_class=Regression::Multiple::RubyEngine if r_class.nil?
        @lr=r_class.new(ds,y_var)
      end
      def add_contribution(f,v)
        @contributions[f]=v-r2
      end
      def r2
        @lr.r2
      end
      def add_table_row
        begin
        sign=sprintf("%0.3f", @lr.significance)
        rescue RuntimeError
            sign="???"
        end
        [@name.join("*"), sprintf("%0.3f",r2), sign] + @fields.collect{|k|
          v=@contributions[k]
          if v.nil?
              "--"
          else
          sprintf("%0.3f",v)
          end
        }
      end
      def summary
        out=sprintf("%s: r2=%0.3f(p=%0.2f)\n",@name.join("*"),r2,@lr.significance,@lr.sst)
        out << @fields.collect{|k|
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
