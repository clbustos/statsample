module RubySS
    # module for regression methods 
    module Regression
		# Class for calculation of linear regressions
		# To create a LinearRegression object:
		# * <tt> LinearRegression.new_from_vectors(vx,vy)</tt>
		# * <tt> LinearRegression.new_from_gsl(gsl) </tt>
		#
		class LinearRegression
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
				(0...@vx.size).inject(0) {|a,i|
                    a+((@vy[i]-y(@vx[i]))**2)
				}				
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
            def r
                @b * (@vx.sds / @vy.sds)
            end
            def r2
                r**2
            end
            class << self
				def new_from_gsl(ar)
					new(:init_gsl, *ar)
				end
				def new_from_vectors(vx,vy)
					@vx,@vy=RubySS.only_valid(vx,vy)
					r_gsl=GSL::Fit.linear(@vx.gsl, @vy.gsl)
					new(:init_gsl_vectors, @vx,@vy,r_gsl)
				end
			end
			def init_gsl_vectors(vx,vy,r_gsl)
				@vx=vx
				@vy=vy
				init_gsl(*r_gsl)
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
        class << self
			
			def r2_adjusted(r2,n,k)
				1-((1-r2)*((n.to_f-1) / (n-k-1).to_f))
				
			end
        end
    end
end
