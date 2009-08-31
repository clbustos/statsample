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
        
    end
end
end
