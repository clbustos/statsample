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
			# Calculate Point biserial correlation.
			# Equal to Pearson correlation, with one dichotomous value replaced
			# by "0" and the other by "1"
			def point_biserial(dichotomous,continous)
				ds={'d'=>dichotomous,'c'=>continous}.to_dataset.dup_only_valid
				raise(TypeError, "First vector should be dichotomous") if ds['d'].factors.size!=2
				raise(TypeError, "Second vector should be continous") if ds['c'].type!=:scale
				f0=ds['d'].factors[0]
				m0=ds.filter_field('c') {|c| c['d']==f0}
				m1=ds.filter_field('c') {|c| c['d']!=f0}
				((m0.mean-m1.mean).to_f / ds['c'].sdp) * Math::sqrt(m0.size*m1.size.to_f / ds.cases**2)
			end
			# Kendall Rank Correlation Coefficient.
			# Based on Hervé Adbi article
			def tau(v1,v2)
				v1a,v2a=RubySS.only_valid(v1,v2)
				n=v1.size
				v1r,v2r=v1a.ranked(:scale),v2a.ranked(:scale)
				o1=ordered_pairs(v1r)
				o2=ordered_pairs(v2r)
				delta= o1.size*2-(o2  & o1).size*2
				1-(delta * 2 / (n*(n-1)).to_f)
			end
			
			def ordered_pairs(vector)
			d=vector.data
			a=[]
			(0...(d.size-1)).each{|i|
				((i+1)...(d.size)).each {|j|
					a.push([d[i],d[j]])
				}
			}
			a
			end
        end
    end
end

