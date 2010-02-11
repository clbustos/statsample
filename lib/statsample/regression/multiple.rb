require 'statsample/regression/multiple/baseengine'
module Statsample
  module Regression
    # Module for Linear Multiple Regression Analysis.
    # 
    # You can call Statsample::Regression::Multiple.listwise,  Statsample::Regression::Multiple.pairwise or instance directly the engines.
    # 
    #  Use:.
    #
    #  require 'statsample'
    #  a=1000.times.collect {rand}.to_scale
    #  b=1000.times.collect {rand}.to_scale
    #  c=1000.times.collect {rand}.to_scale
    #  ds={'a'=>a,'b'=>b,'c'=>c}.to_dataset
    #  ds['y']=ds.collect{|row| row['a']*5+row['b']*3+row['c']*2+rand()}
    #  lr=Statsample::Regression::Multiple.listwise(ds,'y')
    #  puts lr.summary
    #  Summary for regression of a,b,c over y
    #  *************************************************************
    #  Engine: Statsample::Regression::Multiple::AlglibEngine
    #  Cases(listwise)=1000(1000)
    #  r=0.986
    #  r2=0.973
    #  Equation=0.504+5.011a + 2.995b + 1.988c
    #  ----------------------------
    #  ANOVA TABLE
    #  --------------------------------------------------------------
    #  |  source     | ss       | df  | ms      | f         | s     |
    #  --------------------------------------------------------------
    #  |  Regression | 2979.321 | 3   | 993.107 | 12040.067 | 0.000 |
    #  |  Error      | 82.154   | 996 | 0.082   |           |       |
    #  |  Total      | 3061.475 | 999 |         |           |       |
    #  --------------------------------------------------------------
    #  Beta coefficientes
    #  -----------------------------------------------
    #  |  coeff    | b     | beta  | se    | t       |
    #  -----------------------------------------------
    #  |  Constant | 0.504 | -     | 0.030 | 16.968  |
    #  |  a        | 5.011 | 0.832 | 0.031 | 159.486 |
    #  |  b        | 2.995 | 0.492 | 0.032 | 94.367  |
    #  |  c        | 1.988 | 0.323 | 0.032 | 62.132  |
    #  -----------------------------------------------
    # 
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
