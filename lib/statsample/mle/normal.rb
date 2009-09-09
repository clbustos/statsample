module Statsample
    module MLE
        # Normal Distribution MLE estimation.
        # Usage:
        # 
        #   mle=Statsample::MLE::Normal.new
        #   mle.newton_raphson(x,y)
        #   beta=mle.parameters
        #   likehood=mle.likehood(x,y,beta)
        #   iterations=mle.iterations

        class Normal < BaseMLE
            # Total MLE for given X, Y and B matrices
            def log_likehood(x,y,b)
                n=x.row_size.to_f
                sigma2=b[b.row_size-1,0]
                betas=Matrix.columns([b.column(0). to_a[0...b.row_size-1]])
                e=y-(x*betas)
                last=(1 / (2*sigma2))*e.t*e
                (-(n / 2.0) * Math::log(2*Math::PI))-((n / 2.0)*Math::log(sigma2)) - last[0,0]
            end
            # First derivative for Normal Model.
            # p should be [k+1,1], because the last parameter is sigma^2
            def first_derivative(x,y,p)
                raise "x.rows!=y.rows" if x.row_size!=y.row_size
                raise "x.columns+1!=p.rows" if x.column_size+1!=p.row_size
                
                n = x.row_size
                k = x.column_size
                b = Array.new(k)
                k.times{|i| b[i]=[p[i,0]]}
                beta = Matrix.rows(b)
                sigma2 = p[k,0]
                sigma4=sigma2*sigma2
                e = y-(x*(beta))
                xte = x.transpose*(e)
                ete = e.transpose*(e)
                #rows of the Jacobian
                rows = Array.new(k+1)
                k.times{|i| rows[i] = [xte[i,0] / sigma2]}
                rows[k] = [ete[0,0] / (2*sigma4) - n / (2*sigma2)]
                fd = Matrix.rows(rows, true)
            end
            
            # second derivative for normal model
             # p should be [k+1,1], because the last parameter is sigma^2
            def second_derivative(x,y,p)
                raise "x.rows!=y.rows" if x.row_size!=y.row_size
                raise "x.columns+1!=p.rows" if x.column_size+1!=p.row_size

                n = x.row_size
                k = x.column_size
                b = Array.new(k)
                k.times{|i| b[i]=[p[i,0]]}
                beta = Matrix.rows(b)
                sigma2 = p[k,0]
                sigma4=sigma2*sigma2
                sigma6 = sigma2*sigma2*sigma2
                e = y-(x*(beta))
                xtx = x.transpose*(x)
                xte = x.transpose*(e)
                ete = e.transpose*(e)
                #rows of the Hessian
                rows = Array.new(k+1)
                k.times do |i|
                    row = Array.new(k+1)
                    k.times do |j|
                        row[j] = -xtx[i,j] / sigma2
                    end
                    row[k] = -xte[i,0] / sigma4
                    rows[i] = row
                end
                last_row = Array.new(k+1)
                k.times do |i|
                    last_row[i] = -xte[i,0] / sigma4
                end
                last_row[k] = 2*sigma4 - ete[0,0] / sigma6
                rows[k] = last_row
                sd = Matrix.rows(rows, true)
            end
        end
    end
end
