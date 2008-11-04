module RubySS
    # module for regression methods 
    module Regression
        class << self
			def linear_regression(v1,v2)
                raise "You need Ruby/GSL" unless HAS_GSL
				v1a,v2a=RubySS.only_valid(v1,v2)
				GSL::Fit.linear(v1a.gsl, v2a.gsl)
			end
			def r2_adjusted(r2,n,k)
				1-((1-r2)*((n.to_f-1) / (n-k-1).to_f))
				
			end
        end
    end
end
