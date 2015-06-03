require 'statsample/regression/simple'
require 'statsample/regression/multiple'

require 'statsample/regression/multiple/matrixengine'
require 'statsample/regression/multiple/rubyengine'
require 'statsample/regression/multiple/gslengine'

module Statsample
    # = Module for regression procedures.
    # Use the method on this class to generate
    # analysis.
    # If you need more control, you can
    # create and control directly the objects who computes
    # the regressions.
    # 
    # * Simple Regression :  Statsample::Regression::Simple
    # * Multiple Regression: Statsample::Regression::Multiple
    # * Logit Regression:    Statsample::Regression::Binomial::Logit
    # * Probit Regression:    Statsample::Regression::Binomial::Probit
    module Regression
      
      LinearDependency=Class.new(Exception)
      
      # Create a Statsample::Regression::Simple object, for simple regression
      # * x: independent Vector
      # * y: dependent Vector
      # <b>Usage:</b>
      #   x = Daru::Vector.new(100.times.collect {|i| rand(100)})
      #   y = Daru::Vector.new(100.times.collect {|i| 2+x[i]*2+rand()})
      #   sr=Statsample::Regression.simple(x,y)
      #   sr.a
      #   => 2.51763295177808
      #   sr.b
      #   => 1.99973746599856
      #   sr.r
      #   => 0.999987881153254
      def self.simple(x,y)
        Statsample::Regression::Simple.new_from_vectors(x,y)
      end
      
      # Creates one of the Statsample::Regression::Multiple object,
      # for OLS multiple regression.
      # Parameters:
      # * <tt>ds</tt>: Dataset.
      # * y: Name of dependent variable.
      # * opts: A hash with options
      #   * missing_data: Could be
      #     * :listwise: delete cases with one or more empty data (default).
      #     * :pairwise: uses correlation matrix. Use with caution.
      # 
      # <b>Usage:</b>
      #   lr=Statsample::Regression::multiple(ds,:y)
      def self.multiple(ds,y_var, opts=Hash.new)
        missing_data= (opts[:missing_data].nil? ) ? :listwise : opts.delete(:missing_data)
        if missing_data==:pairwise
           Statsample::Regression::Multiple::RubyEngine.new(ds,y_var, opts)
        else
          if Statsample.has_gsl? and false
            Statsample::Regression::Multiple::GslEngine.new(ds, y_var, opts)
          else
            ds2=ds.dup_only_valid
            Statsample::Regression::Multiple::RubyEngine.new(ds2,y_var, opts)
          end
        end
      end
    end
end
