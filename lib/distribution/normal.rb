module Distribution
  # Calculate cdf and inverse cdf for Normal Distribution.
  # Uses Statistics2 module
  module Normal
    class << self
      # Return a proc which return a random number within a gaussian distribution -> N(0,1)
      # == Reference:
      # * http://www.taygeta.com/random/gaussian.html
      def rng_ugaussian
        if Distribution.has_gsl?
          rng=GSL::Rng.alloc()
          lambda { rng.ugaussian()}
        else
          returned,y1,y2=0,0,0
          lambda {
            if returned==0
              begin
                x1 = 2.0 * rand - 1.0
                x2 = 2.0 * rand - 1.0
                w = x1 * x1 + x2 * x2
              end while ( w >= 1.0 )
              w = Math::sqrt( (-2.0 * Math::log( w ) ) / w )
              y1 = x1 * w
              y2 = x2 * w
              returned=1
              y1
            else
              returned=0
              y2
            end
          }
        end
      end
      # Return the P-value of the corresponding integral
      def p_value(pr)
          Statistics2.pnormaldist(pr)
      end
      # Normal cumulative distribution function (cdf).
      # 
      # Returns the integral of  normal distribution 
      # over (-Infty, x].
      # 
      def cdf(x)
        Statistics2.normaldist(x)
      end

      if Distribution.has_gsl?
        alias :cdf_ruby :cdf 
        def cdf(x) # :nodoc:
          GSL::Cdf::gaussian_P(x)
        end
      end
      # Normal probability density function (pdf)
      # With x=0 and sigma=1
      def pdf(x)
          (1.0/Math::sqrt(2*Math::PI))*Math::exp(-(x**2/2.0))
      end
    end
  end
end
