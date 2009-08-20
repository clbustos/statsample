module Statsample
module Regression
    class Logit
        def initialize(ds,y_var)
        @ds=ds
        @y_var=y_var
        end
        def vp(x1,x2)
            sum=0
            x1.each_index{|i|
                sum+=x1[i]*x2[i]
            }
            sum
        end
        # F(B'Xi)
        def f(b,x)
            Math::exp(vp(b,x)) / (1+Math::exp(vp(b,x)))
        end
        # f(B'Xi)
        def fa(b,x)
            f(b,x)*(1-f(b,x))
        end
        def l(b)
            prod=1
            y=@ds[@y_var]
            @ds.each_array{|x|
                x.unshift(1) # add constant
                l=(f(b,x)**y[@ds.i])*((1.0-f(b,x))**(1.0-y[@ds.i]))
                prod=prod*l
            }
            prod
        end
    end
end
end
