module Statsample
  module Minimization
    # Basic minimization algorithm. Slow, but robust
    
    class GoldenSection
      EPSILON=1e-6
      MAX_ITERATIONS=100
      attr_reader :x_minimum, :f_minimum, :log
      def initialize(lower,upper, proc)
        raise "first argument  should be lower than second" if lower>=upper
        @lower=lower
        @upper=upper
        @estimate=(@lower+@upper).quo(2)
        @proc=proc
        @max_iteration=MAX_ITERATIONS
        @epsilon=EPSILON
        @iterations=0
        @log=""
      end
      def f(x)
        @proc.call(x)
      end
      def iterate
        ax=@lower
        bx=@estimate
        cx=@upper
        c = (3-Math::sqrt(5)).quo(2);
        r = 1-c;
 
        x0 = ax;
        x3 = cx;
        if ((cx-bx).abs > (bx-ax).abs)
          x1 = bx;
          x2 = bx + c*(cx-bx);
        else
          x2 = bx;
          x1 = bx - c*(bx-ax);
        end
        f1 = f(x1);
        f2 = f(x2);
         
        k = 1;
        while (x3-x0).abs > @epsilon*(x1.abs+x2.abs) and k<@max_iteration
          @log+=sprintf("k=%4d, |a-b|=%e\n", k, (x3-x0).abs)
          if f2 < f1
            x0 = x1;
            x1 = x2;
            x2 = r*x1 + c*x3;   # x2 = x1+c*(x3-x1)
            f1 = f2;
            f2 = f(x2);
          else
            x3 = x2;
            x2 = x1;
            x1 = r*x2 + c*x0;   # x1 = x2+c*(x0-x2)
            f2 = f1;
            f1 = f(x1);
          end
          k +=1;
        end
         
        if f1 < f2
          @x_minimum = x1;
          @f_minimum = f1;
        else
          @x_minimum = x2;
          @f_minimum = f2;
        end

      end

    end
    
    # Not complete operational. Should use GoldenSection for now
    class Brent
      EPSILON=1e-6
      MAX_ITERATIONS=100
      GOLDEN=(3 - sqrt(5)).quo(2)
      attr_reader :range, :x_minimum, :f_minimum, :log
      def initialize(lower,upper, proc)
        raise "first argument  should be lower than second" if lower>=upper
        @lower=lower
        @upper=upper
        @proc=proc
        @max_iteration=MAX_ITERATIONS
        @epsilon=EPSILON
        @iterations=0
        @log=""
      end
      def f(x)
        @proc.call(x)
      end
      # Need work
      def iterate
        a,b=@lower, @upper
        
        c=a
        
        mflag=true
        d=nil
        @iterations=0
        begin
          @iterations+=1
          fa=f(a)
          fb=f(b)
          fc=f(c)

          if fa!=fc and fb!=fc
            m="iq" #puts "inverse quadratic"
            s = (a*fb*fc).quo((fa-fb)*(fa-fc))+
                (b*fa*fc).quo((fb-fa)*(fb-fc))+
                (c*fa*fb).quo((fc-fa)*(fc-fb))
          else
            m="sec"
            s=b-(fb*((b-a).quo(fb-fa)))
          end
          
          
          if (s<(3*a+b).quo(4) or s>b) or
              ( mflag and (s-b).abs >= (b-c).abs.quo(2)) or
              (!mflag and (s-b).abs >= (c-d).abs.quo(2)) or
              ( mflag and (b-c).abs < @epsilon) or
              (!mflag and (c-d).abs < @epsilon)
            #puts "bisection"
            m="bis"
            s=(a+b).quo(2)
            mflag=true
          else
            #puts "s aceptado"
            mflag=false
          end
          fs=f(s)
          @log+=sprintf("%2d=a:%0.3f (%0.3f) b:%0.3f (%0.3f) s(%s): %0.3f (%0.3f) [e:%f]\n", @iterations, a, fa,b,fb,m,s,fs, a-b)

          #puts sprintf("s:%0.3f (%0.3f)", s,fs)
          d=c
          c=b
          if fa>fb
            a=s
          else
            b=s
          end
          if f(a)<f(b)
            temp=a
            a=b
            b=temp
            
          end
          
          
          #puts "--"
          end while (a-b).abs > @epsilon and @iterations<@max_iteration
          
          if a<b
            @range=[a,b]
          else
            @range=[b,a]
          end
          
          @x_minimum=(fa<fb) ? a : b 
          @f_minimum=(fa<fb) ? fa : fb
      end
    end
  end
end
