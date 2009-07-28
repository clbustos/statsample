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
        # Multiple Regression
        # Based on Alglib library
        if HAS_ALGIB
            class MultipleRegression
                private_class_method :new
                def initialize(init_method, *argv)
                    self.send(init_method, *argv)
                end
                class << self
                    def new_from_dataset(ds,y_var)
                        new(:init_dataset,ds,y_var)
                    end
                end
                def init_dataset(ds,y_var)
                    @ds=ds.dup_only_valid
                    @y_var=y_var
                    @dy=@ds[@y_var]
                    # Create a custom matrix
                    columns=[]
                    @ds.fields.each{|f|
                        columns.push(@ds[f].to_a) unless f==@y_var
                    }
                    @dep_columns=columns.dup
                    columns.push(@ds[@y_var])
                    matrix=Matrix.columns(columns)
                    @lr=Alglib::LinearRegression.build_from_matrix(matrix)
                end
                def coeffs
                    @lr.coeffs
                end
                def constant
                    @lr.constant
                end
                def standarized_coeffs
                    lr_s.coeffs
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
                # Sum of square total
                def sst
                    @dy.sum_of_squared_deviation
                end
                def ssr
                    mean=@dy.mean
                    (0...@ds.cases).inject(0) {|a,i|
                        v=@dep_columns.collect{|v|v[i]}
                        a+((process(v)-mean)**2)
                    }
                end
                def sse
                    sst-ssr
                end
                def r2
                    ssr.quo(sst)
                end
                def r
                    Math::sqrt(r2)
                end
                def predicted
                    0.upto(@ds.cases-1).collect{|i|
                        vect=@dep_columns.collect{|v| v[i]}
                        process(vect)
                    }.to_vector(:scale)
                end
                def standarized_predicted
                    predicted.standarized
                end
                def residuals
                    0.upto(@ds.cases-1).collect{|i|
                        vect=@dep_columns.collect{|v| v[i]}
                         @ds[@y_var][i] - process(vect) 
                    }.to_vector(:scale)
                end
                # ???? Not equal to SPSS output
                def standarized_residuals
                    res=residuals
                    red_sd=residuals.sds
                    res.collect {|v|
                        v.quo(red_sd)
                    }.to_vector(:scale)
                end
                def df_r
                    @dep_columns.size
                end
                def df_e
                    @ds.cases-@dep_columns.size-1
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
                
                
            end
        end
    end
end
