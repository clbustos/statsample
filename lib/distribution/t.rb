module Distribution

    # Calculate cdf and inverse cdf for T Distribution.
    # Uses Statistics2 Module.
    module T
        class << self
            # Return the P-value of the corresponding integral with 
            # k degrees of freedom
            def p_value(pr,k)
                Statistics2.ptdist(k, pr)
            end
            # T cumulative distribution function (cdf).
            # 
            # Returns the integral of t-distribution 
            # with n degrees of freedom over (-Infty, x].
            # 
            def cdf(x,k)
                Statistics2.tdist(k, x)
            end
        end
    end
end
