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
			def tau_a(v1,v2)
				v1a,v2a=RubySS.only_valid(v1,v2)
				n=v1.size
				v1r,v2r=v1a.ranked(:scale),v2a.ranked(:scale)
				o1=ordered_pairs(v1r)
				o2=ordered_pairs(v2r)
				delta= o1.size*2-(o2  & o1).size*2
				1-(delta * 2 / (n*(n-1)).to_f)				
			end
			# Calculates Tau b correlation
			# Tau-b defines perfect association as strict monotonicity.
			# Although it requires strict monotonicity to reach 1.0, 
			# it does not penalize ties as much as some other measures. 
			# Source: http://faculty.chass.ncsu.edu/garson/PA765/assocordinal.htm
			def tau_b(matrix)
				v=pairs(matrix)
				((v['P']-v['Q']).to_f / Math::sqrt((v['P']+v['Q']+v['Y'])*(v['P']+v['Q']+v['X'])).to_f)
			end
			# Calculates Goodman and Kruskal's gamma
			# Gamma is the surplus of concordant pairs over discordant pairs, 
			# as a percentage of all pairs ignoring ties
			# Source: http://faculty.chass.ncsu.edu/garson/PA765/assocordinal.htm			
			def gamma(matrix)
				v=pairs(matrix)
				(v['P']-v['Q']).to_f / (v['P']+v['Q']).to_f
			end
			# Calculate indexes for a matrix
			# the rows and cols has to be ordered
			def pairs(matrix)
				# calculate concordant
				#p matrix
				rs=matrix.row_size
				cs=matrix.column_size
				conc=disc=ties_x=ties_y=0
				(0...(rs-1)).each {|x|
					(0...(cs-1)).each{|y|
						((x+1)...rs).each{|x2|
							((y+1)...cs).each{|y2|
								#p sprintf("%d:%d,%d:%d",x,y,x2,y2)
								conc+=matrix[x,y]*matrix[x2,y2]
							}
						}
					}
				}
				(0...(rs-1)).each {|x|
					(1...(cs)).each{|y|
						((x+1)...rs).each{|x2|
							(0...y).each{|y2|
								#p sprintf("%d:%d,%d:%d",x,y,x2,y2)
								disc+=matrix[x,y]*matrix[x2,y2]
							}
						}
					}
				}
				(0...(rs-1)).each {|x|
					(0...(cs)).each{|y|
						((x+1)...(rs)).each{|x2|
							ties_x+=matrix[x,y]*matrix[x2,y]
						}
					}
				}
				(0...rs).each {|x|
					(0...(cs-1)).each{|y|
						((y+1)...(cs)).each{|y2|
							ties_y+=matrix[x,y]*matrix[x,y2]
						}
					}
				}
				{'P'=>conc,'Q'=>disc,'Y'=>ties_y,'X'=>ties_x}
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

