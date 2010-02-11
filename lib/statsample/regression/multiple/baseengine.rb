module Statsample
  module Regression
    module Multiple
      # Base class for Multiple Regression Engines
      class BaseEngine
        include GetText
        bindtextdomain("statsample")
        # Name of analysis
        attr_accessor :name
        def initialize(ds, y_var, opts = Hash.new)
          @ds=ds
          @y_var=y_var
          @r2=nil
          @name=_("Multiple Regression:  %s over %s") % [ ds.fields.join(",") , @y_var]
          opts.each{|k,v|
            self.send("#{k}=",v) if self.respond_to? k
          }
        end

        # Retrieves a vector with predicted values for y
        def predicted
          (0...@ds.cases).collect { |i|
          invalid=false
          vect=@dep_columns.collect {|v| invalid=true if v[i].nil?; v[i]}
          if invalid
            nil
          else
            process(vect)
          end
          }.to_vector(:scale)
        end
        # Retrieves a vector with standarized values for y
        def standarized_predicted
          predicted.standarized
        end
        # Retrieves a vector with residuals values for y
        def residuals
          (0...@ds.cases).collect{|i|
            invalid=false
            vect=@dep_columns.collect{|v| invalid=true if v[i].nil?; v[i]}
            if invalid or @ds[@y_var][i].nil?
              nil
            else
              @ds[@y_var][i] - process(vect)
            end
          }.to_vector(:scale)
        end
        # R Multiple
        def r
          raise "You should implement this"
        end
        # Sum of squares Total
        def sst
          raise "You should implement this"
        end
        # Sum of squares (regression)
        def ssr
          r2*sst
        end
        # Sum of squares (Error)
        def sse
          sst - ssr
        end
        # T values for coeffs
        def coeffs_t
          out={}
          se=coeffs_se
          coeffs.each do |k,v|
            out[k]=v / se[k]
          end
          out
        end
        # Mean square Regression
        def msr
          ssr.quo(df_r)
        end
        # Mean Square Error
        def mse
          sse.quo(df_e)
        end
        # Degrees of freedom for regression
        def df_r
          @dep_columns.size
        end
        # Degrees of freedom for error
        def df_e
          @ds_valid.cases-@dep_columns.size-1
        end
        # Fisher for Anova
        def f
          (ssr.quo(df_r)).quo(sse.quo(df_e))
        end
        # Significance of Fisher
        def significance
          1.0-Distribution::F.cdf(f,df_r,df_e)
        end
        # Tolerance for a given variable
        # http://talkstats.com/showthread.php?t=5056
        def tolerance(var)
          ds=assign_names(@dep_columns)
          ds.each{|k,v|
          ds[k]=v.to_vector(:scale)
          }
          lr=Multiple.listwise(ds.to_dataset,var)
          1-lr.r2
        end
        # Tolerances for each coefficient
        def coeffs_tolerances
          @fields.inject({}) {|a,f|
          a[f]=tolerance(f);
            a
          }
        end
        # Standard Error for coefficients
        def coeffs_se
          out={}
          mse=sse.quo(df_e)
          coeffs.each {|k,v|
            out[k]=Math::sqrt(mse/(@ds[k].sum_of_squares*tolerance(k)))
          }
          out
        end
        # Estimated Variance-Covariance Matrix
        # Used for calculation of se of constant
        def estimated_variance_covariance_matrix
          mse_p=mse
          columns=[]
          @ds_valid.each_vector{|k,v|
            columns.push(v.data) unless k==@y_var
          }
          columns.unshift([1.0]*@ds_valid.cases)
          x=Matrix.columns(columns)
          matrix=((x.t*x)).inverse * mse
          matrix.collect {|i| Math::sqrt(i) if i>0 }
        end
        # T for constant
        def constant_t
          constant.to_f/constant_se
        end
        # Standard error for constant
        def constant_se
          estimated_variance_covariance_matrix[0,0]
        end
        def summary
          rp=ReportBuilder.new()
          rp.add(self)
          rp.to_text
        end
        def to_reportbuilder(generator)
          anchor=generator.add_toc_entry(_("Multiple Regression: ")+@name)
          generator.add_html "<div class='multiple-regression'>#{@name}<a name='#{anchor}'></a>"
          c=coeffs
          generator.add_text(_("Engine: %s") % self.class)
          generator.add_text(_("Cases(listwise)=%d(%d)") % [@ds.cases, @ds_valid.cases])
          generator.add_text("r=#{sprintf('%0.3f',r)}")
          generator.add_text("r=#{sprintf('%0.3f',r2)}")
          
          generator.add_text(_("Equation")+"="+ sprintf('%0.3f',constant) +" + "+ @fields.collect {|k| sprintf('%0.3f%s',c[k],k)}.join(' + ') )
          
          t=ReportBuilder::Table.new(:name=>"ANOVA", :header=>%w{source ss df ms f s})
          t.add_row([_("Regression"), sprintf("%0.3f",ssr), df_r, sprintf("%0.3f",msr), sprintf("%0.3f",f), sprintf("%0.3f", significance)])
          t.add_row([_("Error"), sprintf("%0.3f",sse), df_e, sprintf("%0.3f",mse)])
  
          t.add_row([_("Total"), sprintf("%0.3f",sst), df_r+df_e])
          generator.parse_element(t)
          sc=standarized_coeffs
          cse=coeffs_se
          t=ReportBuilder::Table.new(:name=>"Beta coefficients", :header=>%w{coeff b beta se t}.collect{|field| _(field)} )
          
          t.add_row([_("Constant"), sprintf("%0.3f", constant), "-", sprintf("%0.3f", constant_se), sprintf("%0.3f", constant_t)])
          @fields.each do |f|
            t.add_row([f, sprintf("%0.3f", c[f]), sprintf("%0.3f", sc[f]), sprintf("%0.3f", cse[f]), sprintf("%0.3f", c[f].quo(cse[f]))])
          end  
          generator.parse_element(t)
          generator.add_html("</div>")
        end
        
        
        def assign_names(c)
          a={}
          @fields.each_index {|i|
            a[@fields[i]]=c[i]
          }
          a
        end

        # Deprecated
        # Sum of squares of error (manual calculation)
        # using the predicted value minus the y_i value
        def sse_manual
          pr=predicted
          cases=0
          sse=(0...@ds.cases).inject(0) {|a,i|
          if !@dy.data_with_nils[i].nil? and !pr[i].nil?
            cases+=1
            a+((pr[i]-@dy[i])**2)
          else
            a
          end
          }
          sse*(min_n_valid-1.0).quo(cases-1)
        end
        # Sum of squares of regression
        # using the predicted value minus y mean
        def ssr_direct
          mean=@dy.mean
          cases=0
          ssr=(0...@ds.cases).inject(0) {|a,i|
            invalid=false
            v=@dep_columns.collect{|c| invalid=true if c[i].nil?; c[i]}
            if !invalid
              cases+=1
              a+((process(v)-mean)**2)
            else
              a
            end
          }
          ssr
        end
        def sse_direct
          sst-ssr
        end
        def process(v)
          c=coeffs
          total=constant
          @fields.each_index{|i|
            total+=c[@fields[i]]*v[i]
          }
          total
        end
      end
    end
  end
end