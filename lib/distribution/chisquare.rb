module Distribution
    # Calculate cdf and inverse cdf for Chi Square Distribution.
    # 
    # Based on Babatunde, Iyiola & Eni () : 
    # "A Numerical Procedure for Computing Chi-Square Percentage Points"
    # 
    module ChiSquare
        class << self
            # Return the P-value of the corresponding integral with 
            # k degrees of freedom
            def p_value(pr,k)
                Statistics2.pchi2X_(k, pr)
            end
            # Chi-square cumulative distribution function (cdf).
            # 
            # Returns the integral of Chi-squared distribution 
            # with k degrees of freedom over [0, x]
            # 
            def cdf(x,k)
                Statistics2.chi2dist(k,x)
            end
        end
    end
end
