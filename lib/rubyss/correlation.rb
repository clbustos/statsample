module RubySS
    # module for several statistical correlation 
    module Correlation
        class << self
            # Calculate Pearson correlation coefficient between 2 vectors
            def pearson(v1,v2)
                raise "You need Ruby/GSL" unless HAS_GSL
                ds=Dataset.new({'v1'=>v1,'v2'=>v2}).dup_only_valid
                GSL::Stats::correlation(ds['v1'].gsl, ds['v2'].gsl)
            end
        end
    end
end
