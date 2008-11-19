module RubySS
    # module for regression methods 
    module Regression
		# Class for calculation of linear regressions
		# To create a LinearRegression object:
		# * <tt> LinearRegression.new_from_gsl(gsl) </tt>
		# * <tt> LinearRegression.new_from_vectors(v1,v2)</tt>
		#
		class LinearRegression
			attr_accessor :a,:b,:cov00, :cov01, :cov11, :chisq, :status
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
			def sse
				(0...@v1.size).inject(0) {|a,i|
						a+((@v2[i]-y(@v2[i]))**2)
				}				
			end
			class << self
				def new_from_gsl(ar)
					new(:init_gsl, *ar)
				end
				def new_from_vectors(v1,v2)
					@v1,@v2=RubySS.only_valid(v1,v2)
					r_gsl=GSL::Fit.linear(@v1.gsl, @v2.gsl)
					new(:init_gsl_vectors, @v1,@v2,r_gsl)
				end
			end
			def init_gsl_vectors(v1,v2,r_gsl)
				@v1=v1
				@v2=v2
				init_gsl(*r_gsl)
			end
			def init_gsl(a,b,cov00, cov01, cov11, chisq, status)
				@a=a
				@b=b
				@cov00=cov00
				@cov01=cov01
				@cov11=cov11
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
