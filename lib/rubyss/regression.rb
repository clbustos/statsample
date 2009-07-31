
module RubySS
    # module for regression methods 
    module Regression
		# Class for calculation of linear regressions
		# To create a SimpleRegression object:
		# * <tt> SimpleRegression.new_from_vectors(vx,vy)</tt>
		# * <tt> SimpleRegression.new_from_gsl(gsl) </tt>
		#
		class SimpleRegression
			attr_accessor :a,:b,:cov00, :cov01, :covx1, :chisq, :status
			private_class_method :new
			def initialize(init_method, *argv)
				self.send(init_method, *argv)
			end
			def y(val_x)
				@a+@b*val_x
			end
			def x(val_y)
				(val_y-@a) / @b.to_f
			end
            # Sum of square error
			def sse
				(0...@vx.size).inject(0) {|acum,i|
                    acum+((@vy[i]-y(@vx[i]))**2)
				}				
			end
			def standard_error
				Math::sqrt(sse / (@vx.size-2).to_f)
			end
            # Sum of square regression
            def ssr
                vy_mean=@vy.mean
				(0...@vx.size).inject(0) {|a,i|
                    a+((y(@vx[i])-vy_mean)**2)
				}				
                
            end
            # Sum of square total
            def sst
                @vy.sum_of_squared_deviation
            end
            # Value of r
            def r
                @b * (@vx.sds / @vy.sds)
            end
            # Value of r^2
            def r2
                r**2
            end
            class << self
				def new_from_gsl(ar)
					new(:init_gsl, *ar)
				end
				def new_from_vectors(vx,vy)
                    new(:init_vectors,vx,vy)
				end
			end
            def init_vectors(vx,vy)
                @vx,@vy=RubySS.only_valid(vx,vy)
                x_m=@vx.mean
                y_m=@vy.mean
                num=den=0
                (0...@vx.size).each {|i|
                    num+=(@vx[i]-x_m)*(@vy[i]-y_m)
                    den+=(@vx[i]-x_m)**2
                }
                @b=num.to_f/den
                @a=y_m - @b*x_m
            end
			def init_gsl(a,b,cov00, cov01, covx1, chisq, status)
				@a=a
				@b=b
				@cov00=cov00
				@cov01=cov01
				@covx1=covx1
				@chisq=chisq
				@status=status
			end
		end
        
        
        class MultipleRegressionBase
             def assign_names(c)
                    a={}
                    @fields.each_index {|i|
                        a[@fields[i]]=c[i]
                    }
                    a
            end
            def predicted
                0.upto(@ds.cases-1).collect{|i|
                    invalid=false
                    vect=@dep_columns.collect{|v| invalid=true if v[i].nil?; v[i]}
                    if invalid
                        nil
                    else
                        process(vect)
                    end
                }.to_vector(:scale)
            end
            def standarized_predicted
                predicted.standarized
            end
            def residuals
                0.upto(@ds.cases-1).collect{|i|
                    invalid=false
                    vect=@dep_columns.collect{|v| invalid=true if v[i].nil?; v[i]}
                    if invalid or @ds[@y_var][i].nil?
                        nil
                    else
                     @ds[@y_var][i] - process(vect)
                 end
                }.to_vector(:scale)
            end
            def r
                raise "You should implement this"
            end
            def sst
                raise "You should implement this"
            end
            def ssr
                r2*sst
            end
            def sse
                sst - ssr
            end            
            
            def coeffs_t
                out={}
                se=coeffs_se
                coeffs.each{|k,v|
                    out[k]=v / se[k] 
                }
                out
            end
            
            def mse
                sse/df_e
            end            
            
            def df_r
                @dep_columns.size
            end
            def df_e
                @ds_valid.cases-@dep_columns.size-1
            end
            def f
                (ssr.quo(df_r)).quo(sse.quo(df_e))
            end
            # Significance of Fisher
            def significance
                if HAS_GSL
                    GSL::Cdf.fdist_Q(f,df_r,df_e)
                else
                    raise "Need Ruby/GSL"
                end
            end
                # Tolerance for a given variable
                # http://talkstats.com/showthread.php?t=5056
                def tolerance(var)
                    ds=assign_names(@dep_columns)
                    ds.each{|k,v|
                        ds[k]=v.to_vector(:scale)
                    }
                    lr=MultipleRegression.new(ds.to_dataset,var)
                    1-lr.r2
                end
                def coeffs_tolerances
                    @fields.inject({}) {|a,f|
                        a[f]=tolerance(f);
                        a
                    }
                end
                def coeffs_se
                    out={}
                    mse=sse.quo(df_e)
                    coeffs.each {|k,v|
                        out[k]=Math::sqrt(mse/(@ds[k].sum_of_squares*tolerance(k)))
                    }
                    out
                end
                def estimated_variance_covariance_matrix
                    mse_p=mse
                    columns=[]
                    @ds_valid.each_vector{|k,v|
                        columns.push(v.data) unless k==@y_var
                    }
                    columns.unshift([1.0]*@ds_valid.cases)
                    x=Matrix.columns(columns)
                    matrix=((x.t*x)).inverse * mse
                    matrix.collect {|i|
                        Math::sqrt(i)
                    }
                end
                def constant_t
                    constant.to_f/constant_se 
                end
                def constant_se
                    estimated_variance_covariance_matrix[0,0]
                end
                def summary(report_type=ConsoleSummary)
                    c=coeffs
                    out=""
                    out.extend report_type
                    out.add <<HEREDOC
Summary for regression of #{@fields.join(',')} over #{@y_var}"
*************************************************************
Cases(listwise)=#{@ds.cases}(#{@ds_valid.cases})
r=#{sprintf("%0.3f",r)}
r2=#{sprintf("%0.3f",r2)}
ssr=#{sprintf("%0.3f",ssr)}
sse=#{sprintf("%0.3f",sse)}
sst=#{sprintf("%0.3f",sst)}
F#{sprintf("(%d,%d)=%0.3f, p=%0.3f",df_r,df_e,f,significance)}
Equation=#{sprintf("%0.3f",constant)}+#{@fields.collect {|k| sprintf("%0.3f%s",c[k],k)}.join(' + ')}

HEREDOC
                
                end
                
                
            # Deprecated
            # Sum of squares of error (manual calculation)
            # using the predicted value minus the y_i value
            def sse_manual
                pr=predicted
                cases=0
                sse=(0...@ds.cases).inject(0) {|a,i|
                    if !@dy.data_with_nils[i].nil? and !pr[i].nil?
                        cases+=1
                        a+((pr[i]-@dy[i])**2)
                    else
                        a
                    end
                }
                sse*(min_n_valid-1.0).quo(cases-1)
            end
            # Sum of squares of regression
            # using the predicted value minus y mean
            def ssr_direct
                mean=@dy.mean
                cases=0
                ssr=(0...@ds.cases).inject(0) {|a,i|
                    invalid=false
                    v=@dep_columns.collect{|c| invalid=true if c[i].nil?; c[i]}
                    if !invalid
                        cases+=1
                        a+((process(v)-mean)**2)
                    else
                        a
                    end
                }
                ssr
            end
            def sse_direct
                sst-ssr
            end
                
                
        end
        class MultipleRegressionPairwise < MultipleRegressionBase 
            def initialize(ds,y_var)
                @y_var=y_var
                @dy=ds[@y_var]
                @ds=ds
                @ds_valid=ds.dup_only_valid
                @ds_indep=ds.dup(ds.fields-[y_var])
                @fields=@ds_indep.fields
                set_dep_columns
                obtain_y_vector
                @matrix_x=Bivariate.correlation_matrix(@ds_indep)
                @coeffs_stan=(@matrix_x.inverse*@matrix_y).column(0).to_a
            end
            def min_n_valid
                if @min_n_valid.nil?
                    min=@ds.cases
                    m=Bivariate::n_valid_matrix(@ds)
                    for x in 0...m.row_size
                        for y in 0...m.column_size
                            min=m[x,y] if m[x,y] < min
                        end
                    end
                    @min_n_valid=min
                end
                @min_n_valid
            end
            def set_dep_columns
                @dep_columns=[]
                @ds_indep.each_vector{|k,v|
                    @dep_columns.push(v.data_with_nils)
                }                
            end
            # Sum of square total
            def sst
                #if @sst.nil?
                @sst=@dy.variance*(min_n_valid-1.0)
                #end
                @sst
            end
            def r2
                if @r2.nil?
                c=@matrix_y
                rxx=obtain_predictor_matrix
                matrix=(c.t*rxx.inverse*c)
                @r2=matrix[0,0]
                end
                @r2
            end
            def r
                Math::sqrt(r2)
            end

            def df_e
                min_n_valid-@dep_columns.size-1
            end
            def fix_with_mean
                i=0
                @ds_indep.each{|row|
                    empty=[]
                    row.each{|k,v|
                        empty.push(k) if v.nil?
                    }
                    if empty.size==1
                        @ds_indep[empty[0]][i]=@ds[empty[0]].mean
                    end
                    i+=1
                }
                @ds_indep.update_valid_data
                set_dep_columns
            end
            def fix_with_regression
                i=0
                @ds_indep.each{|row|
                    empty=[]
                    row.each{|k,v|
                        empty.push(k) if v.nil?
                    }
                    if empty.size==1
                        field=empty[0]
                        lr=MultipleRegression.new(@ds_indep,field)
                        fields=[]
                        @ds_indep.fields.each{|f|
                            fields.push(row[f]) unless f==field
                        }
                        @ds_indep[field][i]=lr.process(fields)
                    end
                    i+=1
                }
                @ds_indep.update_valid_data
                set_dep_columns
            end
            def obtain_y_vector
                @matrix_y=Matrix.columns([@ds_indep.fields.collect{|f|
                        Bivariate.pearson(@dy, @ds_indep[f])
                }])
            end
            def obtain_predictor_matrix
                Bivariate::correlation_matrix(@ds_indep)
            end
            def constant
                c=coeffs
                @dy.mean-@fields.inject(0){|a,k| a+(c[k] * @ds_indep[k].mean)}
            end
            def process(v)
                c=coeffs
                total=constant
                @fields.each_index{|i|
                total+=c[@fields[i]]*v[i]
                }
                total
            end
            def coeffs
                sc=standarized_coeffs
                assign_names(@fields.collect{|f|
                    (sc[f]*@dy.sds).quo(@ds_indep[f].sds)
                })
            end
            def standarized_coeffs
                assign_names(@coeffs_stan)
            end
        end
        
        if HAS_ALGIB
        # Class for calculation of multiple regression.
        # Requires Alglib gem.
		# To create a SimpleRegression object:
        #   @a=[1,3,2,4,3,5,4,6,5,7].to_vector(:scale)
        #   @b=[3,3,4,4,5,5,6,6,4,4].to_vector(:scale)
        #   @c=[11,22,30,40,50,65,78,79,99,100].to_vector(:scale)
        #   @y=[3,4,5,6,7,8,9,10,20,30].to_vector(:scale)
        #   ds={'a'=>@a,'b'=>@b,'c'=>@c,'y'=>@y}.to_dataset
        #   lr=RubySS::Regression::MultipleRegression.new(ds,'y')
		#            
            class MultipleRegression < MultipleRegressionBase
                def initialize(ds,y_var)
                    @ds=ds.dup_only_valid
                    @ds_valid=@ds
                    @y_var=y_var
                    @dy=@ds[@y_var]
                    @ds_indep=ds.dup(ds.fields-[y_var])
                    # Create a custom matrix
                    columns=[]
                    @fields=[]
                    @ds.fields.each{|f|
                        if f!=@y_var
                            columns.push(@ds[f].to_a)
                            @fields.push(f)
                        end
                    }
                    @dep_columns=columns.dup
                    columns.push(@ds[@y_var])
                    matrix=Matrix.columns(columns)
                    @lr=Alglib::LinearRegression.build_from_matrix(matrix)
                end
                
                def _dump(i)
                    Marshal.dump({'ds'=>@ds,'y_var'=>@y_var})
                end
                def self._load(data)
                    h=Marshal.load(data)
                    MultipleRegression.new(h['ds'], h['y_var'])
                end
                
                def coeffs
                    assign_names(@lr.coeffs)
                end
                # Coefficients using a constant
                # Based on http://www.xycoon.com/ols1.htm
                def matrix_resolution
                    mse_p=mse
                    columns=@dep_columns.dup.map {|xi| xi.map{|i| i.to_f}}
                    columns.unshift([1.0]*@ds.cases)
                    y=Matrix.columns([@dy.data.map  {|i| i.to_f}])
                    x=Matrix.columns(columns)
                    xt=x.t
                    matrix=((xt*x)).inverse*xt
                    matrix*y
                end
                def r2
                    r**2
                end
                def r
                    Bivariate::pearson(@dy,predicted)
                end  
                def sst
                    @dy.ss
                end
                def constant
                    @lr.constant
                end
                def standarized_coeffs
                    l=lr_s
                    assign_names(l.coeffs)
                end
                def lr_s
                    if @lr_s.nil?
                        build_standarized
                    end
                    @lr_s
                end
                def build_standarized
                    @ds_s=@ds.standarize
                    columns=[]
                    @ds_s.fields.each{|f|
                        columns.push(@ds_s[f].to_a) unless f==@y_var
                    }
                    @dep_columns_s=columns.dup
                    columns.push(@ds_s[@y_var])
                    matrix=Matrix.columns(columns)
                    @lr_s=Alglib::LinearRegression.build_from_matrix(matrix)
                end
                def process(v)
                    @lr.process(v)
                end
                def process_s(v)
                    lr_s.process(v)
                end
                # ???? Not equal to SPSS output
                def standarized_residuals
                    res=residuals
                    red_sd=residuals.sds
                    res.collect {|v|
                        v.quo(red_sd)
                    }.to_vector(:scale)
                end
            end
        end
    end
end
