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
            # 
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
        # Based on GSL algorithm
        
        # I don't know if is correct
        class MultipleRegression
            attr_reader :c,:cov,:chisq,:status
            private_class_method :new
			def initialize(init_method, *argv)
				self.send(init_method, *argv)
			end
            class << self
				def new_from_vectors(vxs,vy)
                    new(:init_vectors,vxs,vy)
				end
			end
            def init_vectors(vxs,vy)
                
                @vxs=vxs
                @vy=vy
                dim=vxs.size
                n=vy.size
                matrix = GSL::Matrix.alloc(n, dim)
                for x in 0...n
                    for y in 0...dim
                        matrix.set(x, y, vxs[y][x])
                    end
                end
                @c, @cov, @chisq, @status = GSL::MultiFit.linear(matrix, vy.gsl)
            end
        end
        class << self
			
			def r2_adjusted(r2,n,k)
				1-((1-r2)*((n.to_f-1) / (n-k-1).to_f))
				
			end
        end
    end
end
