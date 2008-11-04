module RubySS
    # module for correlation methods 
    module Correlation
        class << self
            # Calculate Pearson correlation coefficient between 2 vectors
            def pearson(v1,v2)
                raise "You need Ruby/GSL" unless HAS_GSL
				v1a,v2a=RubySS.only_valid(v1,v2)
                GSL::Stats::correlation(v1a.gsl, v2a.gsl)
            end
			# Calculate Spearman correlation coefficient between 2 vectors
			def spearman(v1,v2)
                raise "You need Ruby/GSL" unless HAS_GSL
				v1a,v2a=RubySS.only_valid(v1,v2)
				v1r,v2r=v1a.ranked(:scale),v2a.ranked(:scale)
                GSL::Stats::correlation(v1r.gsl, v2r.gsl)
			end
        end
    end
end

