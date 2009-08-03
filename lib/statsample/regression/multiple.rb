module Statsample
module Regression
        # Module for Multiple Regression Analysis
        # You can call Regression::Multiple.listwise or Regression::Multiple.pairwise or instance directly the engines
        # Example.
        #
        #  require 'statsample'
        #  @a=[1,3,2,4,3,5,4,6,5,7].to_vector(:scale)
        #  @b=[3,3,4,4,5,5,6,6,4,4].to_vector(:scale)
        #  @c=[11,22,30,40,50,65,78,79,99,100].to_vector(:scale)
        #  @y=[3,4,5,6,7,8,9,10,20,30].to_vector(:scale)
        #  ds={'a'=>@a,'b'=>@b,'c'=>@c,'y'=>@y}.to_dataset
        #  lr=Statsample::Regression::Multiple.listwise(ds,'y')        
        #  #<Statsample::Regression::Multiple::AlglibEngine:0x7f21912e4758 @ds_valid=#<Statsample::Dataset:69891073182680 @fields=[a,b,c,y] labels={"a"=>nil, "b"=>nil, "y"=>nil, "c"=>nil} cases=10, @lr=#<Alglib::LinearRegression:0x7f21912df118 @model=#<Alglib_ext::LinearModel:0x7f21912df708>, @ivars=3, @cases=10, @report=#<Alglib_ext::LrReport:0x7f21912df168>>, @y_var="y", @ds=#<Statsample::Dataset:69891073182680 @fields=[a,b,c,y] labels={"a"=>nil, "b"=>nil, "y"=>nil, "c"=>nil} cases=10, @fields=["a", "b", "c"], @lr_s=nil, @dep_columns=[[1, 3, 2, 4, 3, 5, 4, 6, 5, 7], [3, 3, 4, 4, 5, 5, 6, 6, 4, 4], [11, 22, 30, 40, 50, 65, 78, 79, 99, 100]], @ds_indep=#<Statsample::Dataset:69891073180060 @fields=[a,b,c] labels={"a"=>nil, "b"=>nil, "c"=>nil} cases=10, @dy=Vector(type:scale, n:10)[3,4,5,6,7,8,9,10,20,30]>
        
        
module Multiple
    # Creates an object for listwise regression. According to resources
    # select the best engine
    #   lr=Statsample::Regression::Multiple.listwise(ds,'y')
    def self.listwise(ds,y_var)
        if HAS_ALGIB
            AlglibEngine.new(ds,y_var)
        elsif HAS_GSL
            GslEngine.new(ds,y_var)
        else
            ds2=ds.dup_only_valid
            RubyEngine.new(ds2,y_var)
        end
    end
    
    # Creates an object for pairwise regression
    # For now, always retrieves a RubyEngine
    #    lr=Statsample::Regression::Multiple.listwise(ds,'y')
    def self.pairwise(ds,y_var)
        RubyEngine.new(ds,y_var)
    end

    # Base class for Multiple Regression Engines
    class BaseEngine
    def initialize(ds,y_var)
        @ds=ds
        @y_var=y_var
        @r2=nil
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
        coeffs.each{|k,v|
            out[k]=v / se[k] 
        }
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
        if HAS_GSL
            GSL::Cdf.fdist_Q(f,df_r,df_e)
        else
            raise "Need Ruby/GSL"
        end
    end
        # Tolerance for a given variable
        # http://talkstats.com/showthread.php?t=5056
        def tolerance(var)
            ds=assign_names(@dep_columns)
            ds.each{|k,v|
                ds[k]=v.to_vector(:scale)
            }
    if HAS_ALGIB
        lr_class=AlglibEngine
        ds=ds.to_dataset
    else
        lr_class=RubyEngine
        ds=ds.to_dataset.dup_only_valid
    end
    lr=lr_class.new(ds,var)
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
            matrix.collect {|i|
    
                Math::sqrt(i) if i>0
            }
        end
        # T for constant
        def constant_t
            constant.to_f/constant_se 
        end
        # Standard error for constant
        def constant_se
            estimated_variance_covariance_matrix[0,0]
        end
        # Retrieves a summary for Regression
        def summary(report_type=ConsoleSummary)
            c=coeffs
            out=""
            out.extend report_type
out.add <<HEREDOC
Summary for regression of #{@fields.join(',')} over #{@y_var}
*************************************************************
Engine: #{self.class}
Cases(listwise)=#{@ds.cases}(#{@ds_valid.cases})
r=#{sprintf("%0.3f",r)}
r2=#{sprintf("%0.3f",r2)}
Equation=#{sprintf("%0.3f",constant)}+#{@fields.collect {|k| sprintf("%0.3f%s",c[k],k)}.join(' + ')}
HEREDOC

out.add_line
out.add "ANOVA TABLE"

t=Statsample::ReportTable.new(%w{source ss df ms f s})
t.add_row(["Regression", sprintf("%0.3f",ssr), df_r, sprintf("%0.3f",msr), sprintf("%0.3f",f), sprintf("%0.3f",significance)])

t.add_row(["Error", sprintf("%0.3f",sse), df_e, sprintf("%0.3f",mse)])

t.add_row(["Total", sprintf("%0.3f",sst), df_r+df_e])

out.parse_table(t)
out
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
