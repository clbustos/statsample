require 'statsample/regression/simple'
require 'statsample/regression/multiple'

require 'statsample/regression/multiple/matrixengine'
require 'statsample/regression/multiple/alglibengine'
require 'statsample/regression/multiple/rubyengine'
require 'statsample/regression/multiple/gslengine'

require 'statsample/regression/binomial'
require 'statsample/regression/binomial/logit'
require 'statsample/regression/binomial/probit'

module Statsample
    # = Module for regression procedures.
    # You can use the methods on this module to
    # generate fast results. If you need more control, you can
    # create and control directly the objects who computes
    # the regressions.
    # 
    # * Simple Regression :  Statsample::Regression::Simple
    # * Multiple Regression: Statsample::Regression::Multiple
    # * Logit Regression:    Statsample::Regression::Binomial::Logit
    # * Probit Regression:    Statsample::Regression::Binomial::Probit
    module Regression
      # Create a Logit model object.
      # * ds:: Dataset
      # * y::  Name of dependent vector
      # <b>Usage</b>
      #   dataset=Statsample::CSV.read("data.csv")
      #   y="y" 
      #   lr=Statsample::Regression.logit(dataset,y)
      #   
      def self.logit(ds,y_var)
        Statsample::Regression::Binomial::Logit.new(ds,y_var)                
      end
      # Create a Probit model object.
      # * ds:: Dataset
      # * y::  Name of dependent vector
      # <b>Usage</b>
      #   dataset=Statsample::CSV.read("data.csv")
      #   y="y" 
      #   lr=Statsample::Regression.probit(dataset,y)
      #   
      
      def self.probit(ds,y_var)
        Statsample::Regression::Binomial::Probit.new(ds,y_var)                
      end
      
      
      # Creates an object for OLS multiple regression
      # Parameters:
      # * ds: Dataset.
      # * y: Name of dependent variable.
      # * missing_data: Could be
      #   * :listwise: delete cases with one or more empty data (default).
      #   * :pairwise: uses correlation matrix. Use with caution.
      # 
      # <b>Usage:</b>
      # 
      #   lr=Statsample::Regression::multiple(ds,'y')
      def self.multiple(ds,y_var, missing_data=:listwise)
        if missing_data==:pairwise
           RubyEngine.new(ds,y_var)
        else
          if HAS_ALGIB
            Statsample::Regression::Multiple::AlglibEngine.new(ds,y_var)
          elsif HAS_GSL
            Statsample::Regression::Multiple::GslEngine.new(ds,y_var)
          else
            ds2=ds.dup_only_valid
            Statsample::Regression::Multiple::RubyEngine.new(ds2,y_var)
          end
        end
      end
    end
end
