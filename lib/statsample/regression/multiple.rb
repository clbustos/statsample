require 'statsample/regression/multiple/baseengine'
module Statsample
  module Regression
    # Module for Linear Multiple Regression Analysis
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
        # Creates an object for listwise regression. 
        # Alglib is faster, so is prefered over GSL
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
        def self.listwise_by_exp(ds,exp)
          raise "Not implemented yet"
        end
        # Obtain r2 for regressors
        def self.r2_from_matrices(rxx,rxy)
          matrix=(rxy.transpose*rxx.inverse*rxy)
          matrix[0,0]
        end
        
    end
  end
end
