module Distribution
    # Calculate cdf and inverse cdf for Normal Distribution.
    # Uses Statistics2 module
    module Normal
      class << self
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
        # Normal probability density function (pdf)
        # With x=0 and sigma=1
        def pdf(x)
            (1.0/Math::sqrt(2*Math::PI))*Math::exp(-(x**2/2.0))
        end
      end
    end
end
