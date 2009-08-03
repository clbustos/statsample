module Statsample
    # Diverse correlation methods 
    module Bivariate
        class << self
            # Covariance between two vectors
			def covariance(v1,v2)
				v1a,v2a=Statsample.only_valid(v1,v2)
                return nil if v1a.size==0
				if HAS_GSL
					GSL::Stats::covariance(v1a.gsl, v2a.gsl)
				else
					covariance_slow(v1a,v2a)
				end
			end
			# Covariance. The denominator is n-1
			def covariance_slow(v1a,v2a)
				t=0
				m1=v1a.mean
				m2=v1a.mean
				(0...v1a.size).each {|i|
					t+=((v1a[i]-m1)*(v2a[i]-m2))
				}
				t.to_f / (v1a.size-1)
			end
            # Calculate Pearson correlation coefficient between 2 vectors
            def pearson(v1,v2)
				v1a,v2a=Statsample.only_valid(v1,v2)
                return nil if v1a.size ==0
				if HAS_GSL
					GSL::Stats::correlation(v1a.gsl, v2a.gsl)
				else
					pearson_slow(v1a,v2a)
				end
            end
            #:nodoc:
            def pearson_slow(v1a,v2a)
                v1s,v2s=v1a.vector_standarized_pop,v2a.vector_standarized_pop
                t=0
                siz=v1s.size
                (0...v1s.size).each {|i| t+=(v1s[i]*v2s[i]) }
                t.to_f/v2s.size
            end
            # Retrieves the value for t test for a pearson correlation
            # between two vectors to test the null hipothesis of r=0
            def t_pearson(v1,v2)
				v1a,v2a=Statsample.only_valid(v1,v2)
                r=pearson(v1a,v2a)
                if(r==1.0) 
                    0
                else
                    t_r(r,v1a.size)
                end
            end
            # Retrieves the value for t test for a pearson correlation
            # giving r and vector size
            def t_r(r,size)
                r*Math::sqrt(((size)-2).to_f / (1 - r**2))
            end
            # Retrieves the probability value (a la SPSS)
            # for a given t, size and number of tails
            def prop_pearson(t,size, tails=2)
		if HAS_GSL
                t=-t if t>0
                cdf=GSL::Cdf::tdist_P(t,(size)-2)
                cdf*tails
		else
			raise "Needs ruby-gsl"
		end
            end
            # Returns residual score after delete variance
            # from another variable
            # 
            def residuals(from,del)
                r=Statsample::Bivariate.pearson(from,del)
                froms, dels = from.vector_standarized, del.vector_standarized
                nv=[]
                froms.data_with_nils.each_index{|i|
                    if froms[i].nil? or dels[i].nil?
                        nv.push(nil)
                    else
                        nv.push(froms[i]-r*dels[i])
                    end
                }
                nv.to_vector(:scale)
            end
            def partial_correlation(v1,v2,control)
                v1a,v2a,cona=Statsample.only_valid(v1,v2,control)
                rv1v2=pearson(v1a,v2a)
                rv1con=pearson(v1a,cona)
                rv2con=pearson(v2a,cona)
                
                (rv1v2-(rv1con*rv2con)).quo(Math::sqrt(1-rv1con**2) * Math::sqrt(1-rv2con**2))
                
            end
            # Covariance matrix
            def covariance_matrix(ds)
                ds.collect_matrix do |row,col|
                    if (ds[row].type!=:scale or ds[col].type!=:scale)
                        nil
                    else
                        covariance(ds[row],ds[col])
                    end
                end
            end
            
            # The classic correlation matrix for all fields of a dataset
            
            def correlation_matrix(ds)
                ds.collect_matrix {|row,col|
                        if row==col
                            1.0
                        elsif (ds[row].type!=:scale or ds[col].type!=:scale)
                            nil
                        else
                            pearson(ds[row],ds[col])
                        end
                }
            end
            # Retrieves the n valid pairwise
            def n_valid_matrix(ds)
                ds.collect_matrix {|row,col|
                        if row==col
                            ds[row].valid_data.size
                        else
                            rowa,rowb=Statsample.only_valid(ds[row],ds[col])
                            rowa.size
                        end
                }
            end
            def correlation_probability_matrix(ds)
                rows=ds.fields.collect{|row|
                    ds.fields.collect{|col|
                        v1a,v2a=Statsample.only_valid(ds[row],ds[col])
                        (row==col or ds[row].type!=:scale or ds[col].type!=:scale) ? nil : prop_pearson(t_pearson(ds[row],ds[col]), v1a.size)
                    }
                }
                Matrix.rows(rows)
            end
			# Calculate Spearman correlation coefficient between 2 vectors
			def spearman(v1,v2)
				v1a,v2a=Statsample.only_valid(v1,v2)
				v1r,v2r=v1a.ranked(:scale),v2a.ranked(:scale)
                pearson(v1r,v2r)
			end
			# Calculate Point biserial correlation.
			# Equal to Pearson correlation, with one dichotomous value replaced
			# by "0" and the other by "1"
			def point_biserial(dichotomous,continous)
				ds={'d'=>dichotomous,'c'=>continous}.to_dataset.dup_only_valid
				raise(TypeError, "First vector should be dichotomous") if ds['d'].factors.size!=2
				raise(TypeError, "Second vector should be continous") if ds['c'].type!=:scale
				f0=ds['d'].factors.sort[0]
				m0=ds.filter_field('c') {|c| c['d']==f0}
				m1=ds.filter_field('c') {|c| c['d']!=f0}
				((m1.mean-m0.mean).to_f / ds['c'].sdp) * Math::sqrt(m0.size*m1.size.to_f / ds.cases**2)
			end
			# Kendall Rank Correlation Coefficient.
			#
			# Based on Hervé Adbi article
			def tau_a(v1,v2)
				v1a,v2a=Statsample.only_valid(v1,v2)
				n=v1.size
				v1r,v2r=v1a.ranked(:scale),v2a.ranked(:scale)
				o1=ordered_pairs(v1r)
				o2=ordered_pairs(v2r)
				delta= o1.size*2-(o2  & o1).size*2
				1-(delta * 2 / (n*(n-1)).to_f)				
			end
			# Calculates Tau b correlation.
			#
			# Tau-b defines perfect association as strict monotonicity.
			# Although it requires strict monotonicity to reach 1.0, 
			# it does not penalize ties as much as some other measures. 
			#
			# Source: http://faculty.chass.ncsu.edu/garson/PA765/assocordinal.htm
			def tau_b(matrix)
				v=pairs(matrix)
				((v['P']-v['Q']).to_f / Math::sqrt((v['P']+v['Q']+v['Y'])*(v['P']+v['Q']+v['X'])).to_f)
			end
			# Calculates Goodman and Kruskal's gamma.
			# 
			# Gamma is the surplus of concordant pairs over discordant pairs, 
			# as a percentage of all pairs ignoring ties.
			# 
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
			def sum_of_codeviated(v1,v2)
				v1a,v2a=Statsample.only_valid(v1,v2)
				sum=0
				(0...v1a.size).each{|i|
					sum+=v1a[i]*v2a[i]
				}
				sum-((v1a.sum*v2a.sum) / v1a.size.to_f)
			end
        end
    end
end

