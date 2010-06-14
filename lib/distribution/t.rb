require 'rbconfig'
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
                if RbConfig::CONFIG['arch']=~/i686/
		tdist(k, x)
		else
		Statistics2.tdist(k,x)
		end
            end
              
            # Returns the integral of t-distribution with n degrees of freedom over (-Infty, x].
            def tdist(n, t)
              p_t(n, t)
            end
            
            # t-distribution ([1])
            # (-\infty, x]
            def p_t(df, t)
              c2 = df.to_f / (df + t * t);
              s = Math.sqrt(1.0 - c2)
              s = -s if t < 0.0
              p = 0.0;
              i = df % 2 + 2
              while i <= df
                p += s
                s *= (i - 1) * c2 / i
                i += 2
              end
              if df.is_a? Float or df & 1 != 0
                0.5+(p*Math.sqrt(c2)+Math.atan(t/Math.sqrt(df)))/Math::PI
              else
                (1.0 + p) / 2.0
              end
            end  
              
              
              
        end
    end
end
