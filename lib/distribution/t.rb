module Distribution
    # Based on Babatunde, Iyiola & Eni () : 
    # "A Numerical Procedure for Computing Chi-Square Percentage Points"
    # 
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
