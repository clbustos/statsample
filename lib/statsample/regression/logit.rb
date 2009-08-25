module Statsample
module Regression
    class Logit
        def initialize(ds,y_var)
            @ds=ds
            @y_var=y_var
            @dy=@ds[@y_var]
            @ds_indep=ds.dup(ds.fields-[y_var])
        end
        # Vector multiplication
        def vm(x1,x2)
            raise "Both vectors should be equal" if x1.size!=x2.size
            sum=0.0
            x1.each_index{|i|
                sum+=x1[i]*x2[i]
            }
            sum
        end
        # F(B'Xi)
        def f(b,x)
            Math::exp(vm(b,x)).quo(1.0+Math::exp(vm(b,x)))
        end
        # f(B'Xi)
        def fa(b,x)
            f(b,x)*(1-f(b,x))
        end
        def pl(b,x,y)
            (f(b,x)**(y))*((1.0-f(b,x))**(1.0-y))
        end
        def mle_log(b)
            sum=0
            @ds_indep.each_array{|x|
                y=@dy[@ds_indep.i]
                sum+=(y*Math::log(f(b,x)))+((1.0-y)*Math::log(1-f(b,x)))
            }
            sum
        end
        def mle(b)
            prod=1
            @ds_indep.each_array{|x|
                prod=prod*pl(b,x,@dy[@ds_indep.i])
            }
            prod
        end
        def first_derivative(pars)
            k=@ds_indep.fields.size
            fd = Array.new(k)
            k.times {|i| fd[i] = 0.0}
            @ds_indep.each_array{ |x|
                y=@dy[@ds_indep.i]
                val=y-f(pars,x)
                x.each_index{|i2| 
                fd[i2]=fd[i2]+(x[i2]*val)}
            }
            fd
        end
        def test_first_derivative(pars) #:nodoc:
            x=@ds_indep.to_matrix
            y=@dy.to_matrix(:vertical)
            pars=pars.to_matrix(:vertical)
            self.first_derivative_extern(x,y,pars)
        end
        # First derivative of log-likehood function
        def self.first_derivative_extern(x,y,p)
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
        def self.second_derivative_extern(x,y,p)
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
        
        def p_minus(x_row,p)
            value = 0;
            x_row.each_index { |i| value += x_row[i]*p[i,0]}
            1/(1+Math.exp(-value))
        end
        def p_plus(x_row,p)
            value = 0;
            x_row.each_index { |i| value += x_row[i]*p[i,0]}
            1/(1+Math.exp(value))
        end

        # Newton Raphson without automatic stopping criteria.
        # Source: Maximum Likelihood Estimation With Java and Ruby
        # Author: Peter von Tessin
        # Date: November 6, 2005

        def self.newton_raphson(x,y,start_values, model)
          # deep copy?
          parameters = start_values
          20.times do
            h = model.second_derivative(x,y,parameters)
            if h.singular?
                raise "Hessian is singular!"
            end
            fd = model.first_derivative(x,y,parameters)
            parameters = parameters-(h.inverse*(fd))
          end
          parameters
        end
    end
end
end
