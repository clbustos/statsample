require 'matrix_extension'
module Statsample
    module MLE
        # Probit MLE estimation.
        # Usage:
        # 
        #   mle=Statsample::MLE::Probit.new
        #   mle.newton_raphson(x,y)
        #   beta=mle.parameters
        #   likehood=mle.likehood(x,y,beta)
        #   iterations=mle.iterations
        class Probit < BaseMLE
        # F(B'Xi)
        if  HAS_GSL
            # F(B'Xi)
            def f(b,x)
                p_bx=(x*b)[0,0] 
                GSL::Cdf::ugaussian_P(p_bx)
            end
            # f(B'Xi)
            def ff(b,x)
                p_bx=(x*b)[0,0] 
                GSL::Ran::ugaussian_pdf(p_bx)
            end
        else
            def f(b,x) #:nodoc:
                p_bx=(x*b)[0,0] 
                Distribution::Normal.cdf(p_bx)
            end
            def ff(b,x) #:nodoc:
                p_bx=(x*b)[0,0] 
                Distribution::Normal.pdf(p_bx)
                
            end
        end
        # Log Likehood for x_i vector, y_i scalar and b parameters
        def log_likehood_i(xi,yi,b)
            fbx=f(b,xi)
            (yi.to_f*Math::log(fbx))+((1.0-yi.to_f)*Math::log(1.0-fbx))
        end
        # First derivative of log-likehood probit function
        # x: Matrix (NxM)
        # y: Matrix (Nx1)
        # p: Matrix (Mx1)
        def first_derivative(x,y,b)
                raise "x.rows!=y.rows" if x.row_size!=y.row_size
                raise "x.columns!=p.rows" if x.column_size!=b.row_size            
            n = x.row_size
            k = x.column_size
            fd = Array.new(k)
            k.times {|i| fd[i] = [0.0]}
            n.times do |i|
	            xi = Matrix.rows([x.row(i).to_a])
	            fbx=f(b,xi)
                value1 = (y[i,0]-fbx)/ ( fbx*(1-fbx))*ff(b,xi) 
            k.times do |j|
	            fd[j][0] += value1*xi[0,j]
	            end
            end
            Matrix.rows(fd, true)
        end
        # Second derivative of log-likehood probit function
        # x: Matrix (NxM)
        # y: Matrix (Nx1)
        # p: Matrix (Mx1)

        def second_derivative(x,y,b)
            raise "x.rows!=y.rows" if x.row_size!=y.row_size
            raise "x.columns!=p.rows" if x.column_size!=b.row_size
            n = x.row_size
            k = x.column_size
            if HAS_GSL
                sum=GSL::Matrix.zeros(k)
            else
                sum=Matrix.zero(k)
            end
            n.times do |i|
                xi=Matrix.rows([x.row(i).to_a])
                fbx=f(b,xi)
                val=((ff(b,xi)**2) / (fbx*(1.0-fbx)))*xi.t*xi
                if HAS_GSL
                    val=val.to_gsl
                end
                sum-=val
            end
            if HAS_GSL
                sum=sum.to_matrix
            end
            sum
        end
        end # Probit
    end # MLE
end # Statsample
