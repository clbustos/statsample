module RubySS
    # module for several correlation and regression methods 
    module Correlation
        class << self
            # Calculate Pearson correlation coefficient between 2 vectors
            def pearson(v1,v2)
                raise "You need Ruby/GSL" unless HAS_GSL
				v1a,v2a=RubySS.only_valid(v1,v2)
                GSL::Stats::correlation(v1a.gsl, v2a.gsl)
            end
			def linear_regression(v1,v2)
                raise "You need Ruby/GSL" unless HAS_GSL
				v1a,v2a=RubySS.only_valid(v1,v2)
				GSL::Fit.linear(v1a.gsl, v2a.gsl)
			end
        end
    end
end
