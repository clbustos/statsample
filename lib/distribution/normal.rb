module Distribution
    # Uses statistics2
    # 
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
        end
    end
end
