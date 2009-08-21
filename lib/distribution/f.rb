module Distribution
    # Based on Babatunde, Iyiola & Eni () : 
    # "A Numerical Procedure for Computing Chi-Square Percentage Points"
    # 
    module F
        class << self
            # Return the P-value of the corresponding integral with 
            # k degrees of freedom
            def p_value(pr,k1,k2)
                Statistics2.pfdist(k1,k2, pr)
            end
            # F cumulative distribution function (cdf).
            # 
            # Returns the integral of F-distribution 
            # with k1 and k2 degrees of freedom
            # over [0, x].

            # 
            def cdf(x, k1, k2)
                Statistics2.fdist(k1, k2,x)
            end
        end
    end
end
