module Distribution
  # Calculate pdf and cdf for bivariate normal distribution.
  module NormalBivariate
    
    class << self
      SIDE=0.1 # :nodoc:
      LIMIT=5 # :nodoc:
      
      # Probability density function for a given x, y and rho value.
      # 
      # Source: http://en.wikipedia.org/wiki/Multivariate_normal_distribution
      def pdf(x,y, rho, sigma1=1.0, sigma2=1.0)
        (1.quo(2 * Math::PI * sigma1*sigma2 * Math::sqrt( 1 - rho**2 ))) *
          Math::exp(-(1.quo(2*(1-rho**2))) *
          ((x**2/sigma1) + (y**2/sigma2) - (2*rho*x*y).quo(sigma1*sigma2)  ))
      end
      
      def f(x,y,aprime,bprime,rho) 
        r=aprime*(2*x-aprime)+bprime*(2*y-bprime)+2*rho*(x-aprime)*(y-bprime)
        Math::exp(r)
      end
      
      # CDF for a given x, y and rho value.
      # Uses cdf_math method.
      #
      def cdf(a,b,rho)
        cdf_math(a,b,rho)
      end
      
      def sgn(x)
        if(x>=0)
        1
        else
        -1
        end     
      end
      
      # Normal cumulative distribution function (cdf) for a given x, y and rho.
      # Based on (Hull, 1993, cited by Arne, 2003)
      #
      # References:
      # * Arne, B.(2003). Financial Numerical Recipes in C ++. Available on  http://finance.bi.no/~bernt/gcc_prog/recipes/recipes/node23.html
      def cdf_math(a,b,rho)
        #puts "a:#{a} - b:#{b} - rho:#{rho}"
        if (a<=0 and b<=0 and rho<=0)
         # puts "ruta 1"
          aprime=a.quo(Math::sqrt(2.0*(1.0-rho**2)))
          bprime=b.quo(Math::sqrt(2.0*(1.0-rho**2)))
          aa=[0.3253030, 0.4211071, 0.1334425, 0.006374323]
          bb=[0.1337764, 0.6243247, 1.3425378, 2.2626645]
          sum=0
          4.times do |i|
            4.times do |j|
              sum+=aa[i]*aa[j] * f(bb[i], bb[j], aprime, bprime,rho)
            end
          end
          sum=sum*(Math::sqrt(1.0-rho**2).quo(Math::PI))
          return sum
        elsif(a*b*rho<=0.0)
          
          #puts "ruta 2"
          if(a<=0 and b>=0 and rho>=0)
            return Distribution::Normal.cdf(a) - cdf(a,-b,-rho)
          elsif (a>=0.0 and b<=0.0 and rho>=0)
            return Distribution::Normal.cdf(b) - cdf(-a,b,-rho)
          elsif (a>=0.0 and b>=0.0 and rho<=0)
            return Distribution::Normal.cdf(a) + Distribution::Normal.cdf(b) - 1.0 + cdf(-a,-b,rho)
          end
        elsif (a*b*rho>=0.0)
          #puts "ruta 3"
          denum=Math::sqrt(a**2 - 2*rho*a*b + b**2)
          rho1=((rho*a-b)*sgn(a)).quo(denum)
          rho2=((rho*b-a)*sgn(b)).quo(denum)
          delta=(1.0-sgn(a)*sgn(b)).quo(4)
          #puts "#{rho1} - #{rho2}"
          return cdf(a, 0.0, rho1) + cdf(b, 0.0, rho2) - delta
        end
        raise "Should'nt be here! #{a} - #{b} #{rho}"
      end
      
      # CDF. Iterative method. 
      # 
      # Reference:
      # * Jantaravareerat, M. & Thomopoulos, N. (n/d). Tables for standard bivariate normal distribution
     
      def cdf_iterate(x,y,rho,s1=1,s2=1) # :nodoc:
        # Special cases
        return 1 if x>LIMIT and y>LIMIT
        return 0 if x<-LIMIT or y<-LIMIT
        return Distribution::Normal.cdf(y) if  x>LIMIT
        return Distribution::Normal.cdf(x) if  y>LIMIT

        #puts "x:#{x} - y:#{y}"
        x=-LIMIT if x<-LIMIT
        x=LIMIT if x>LIMIT
        y=-LIMIT if y<-LIMIT
        y=LIMIT if y>LIMIT

        x_squares=((LIMIT+x) / SIDE).to_i
        y_squares=((LIMIT+y) / SIDE).to_i
        sum=0
        x_squares.times do |i|
          y_squares.times do |j|
            z1=-LIMIT+(i+1)*SIDE
            z2=-LIMIT+(j+1)*SIDE
            #puts " #{z1}-#{z2}"
            h=(pdf(z1,z2,rho,s1,s2)+pdf(z1-SIDE,z2,rho,s1,s2)+pdf(z1,z2-SIDE,rho,s1,s2) + pdf(z1-SIDE,z2-SIDE,rho,s1,s2)).quo(4)
            sum+= (SIDE**2)*h # area
          end
        end
        sum
      end
      private :f, :sgn 

    end
  end
end
