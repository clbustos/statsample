require 'bigdecimal'
require 'bigdecimal/math'
require 'bigdecimal/util'
module Statsample
    module MLE

        #Logit  model
        module Logit
        class << self
        # F(B'Xi)
        def f(b,x)
            p_bx=(x*b)[0,0] 
            ebx=Math::exp(p_bx)
            if ebx.infinite? == 1
                raise "Infinite on logit calculation"
                return 0.999999999999999
            end
            res=ebx / (1.0 + ebx)
            if res==0.0
                res=1e-15
            elsif res==1.0
                res=0.999999999999999
            end
            res
        end
        def mle(xi,y_val,b)
            (f(b,xi)**y_val)*((1-f(b,xi))**(1-y_val))
        end
        def ln_mle(xi,y_val,b)
            fbx=f(b,xi)
            (y_val.to_f*Math::log(fbx))+((1.0-y_val.to_f)*Math::log(1.0-fbx))
        end
        # First derivative of log-likehood function
        def first_derivative(x,y,p)
                raise "x.rows!=y.rows" if x.row_size!=y.row_size
                raise "x.columns!=p.rows" if x.column_size!=p.row_size            
            n = x.row_size
            k = x.column_size
            fd = Array.new(k)
            k.times {|i| fd[i] = [0.0]}
            n.times do |i|
	            row = x.row(i).to_a
	            value1 = (1-y[i,0]) -p_plus(row,p)
            k.times do |j|
	            fd[j][0] -= value1*row[j]
	            end
            end
            Matrix.rows(fd, true)

        end
        # Second derivative of log-likehood function

        def second_derivative(x,y,p)
                raise "x.rows!=y.rows" if x.row_size!=y.row_size
                raise "x.columns!=p.rows" if x.column_size!=p.row_size             
            n = x.row_size
            k = x.column_size
            sd = Array.new(k)
            k.times do |i|
                arr = Array.new(k)
                k.times{ |j| arr[j]=0.0}
                sd[i] = arr
            end
            n.times do |i|
                row = x.row(i).to_a
                p_m = p_minus(row,p)
                k.times do |j|
                    k.times do |l|
                    sd[j][l] -= p_m *(1-p_m)*row[j]*row[l]
                    end
                end
            end
            Matrix.rows(sd, true)
        end
        private
        def p_minus(x_row,p)
            value = 0.0;
            x_row.each_index { |i| value += x_row[i]*p[i,0]}
            1/(1+Math.exp(-value))
        end
        def p_plus(x_row,p)
            value = 0.0;
            x_row.each_index { |i| value += x_row[i]*p[i,0]}
            1/(1+Math.exp(value))
        end
        end # class
        end # Logit
    end # MLE
end # Statsample
