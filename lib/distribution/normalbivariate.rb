module Distribution
  # Calculate pdf and cdf for bivariate normal distribution.
  #
  # Pdf if easy to calculate, but CDF is not trivial. Several papers
  # describe methods to calculate the integral.
  # 
  # Three methods are implemented on this module:
  # * Genz:: Used by default, with improvement to calculate p on rho > 0.95
  # * Hull:: Port from a C++ code
  # * Jantaravareerat:: Iterative (and slow)
  # 
  
  module NormalBivariate
    
    class << self
      SIDE=0.1 # :nodoc:
      LIMIT=5 # :nodoc:
      
      # Probability density function for a given x, y and rho value.
      # 
      # Source: http://en.wikipedia.org/wiki/Multivariate_normal_distribution
      def pdf(x,y, rho, s1=1.0, s2=1.0)
        1.quo(2 * Math::PI * s1 * s2 * Math::sqrt( 1 - rho**2 )) * (Math::exp(-(1.quo(2*(1-rho**2))) *
          ((x**2.quo(s1)) + (y**2.quo(s2)) - (2*rho*x*y).quo(s1*s2))))
      end
      
      def f(x,y,aprime,bprime,rho) 
        r=aprime*(2*x-aprime)+bprime*(2*y-bprime)+2*rho*(x-aprime)*(y-bprime)
        Math::exp(r)
      end
      
      # CDF for a given x, y and rho value.
      # Uses Genz algorithm (cdf_genz method).
      #
      def cdf(a,b,rho)
        cdf_genz(a,b,rho)
      end
      
      def sgn(x)
        if(x>=0)
        1
        else
        -1
        end     
      end
      
      # Normal cumulative distribution function (cdf) for a given x, y and rho.
      # Based on Hull (1993, cited by Arne, 2003)
      #
      # References:
      # * Arne, B.(2003). Financial Numerical Recipes in C ++. Available on  http://finance.bi.no/~bernt/gcc_prog/recipes/recipes/node23.html
      def cdf_hull(a,b,rho)
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
      
      # CDF. Iterative method by Jantaravareerat (n/d)
      # 
      # Reference:
      # * Jantaravareerat, M. & Thomopoulos, N. (n/d). Tables for standard bivariate normal distribution
     
      def cdf_jantaravareerat(x,y,rho,s1=1,s2=1)
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
      # Normal cumulative distribution function (cdf) for a given x, y and rho.
      # Ported from Fortran code by Alan Genz
      #
      # Original documentation
      #    DOUBLE PRECISION FUNCTION BVND( DH, DK, R )
      #    A function for computing bivariate normal probabilities.
      #
      #       Alan Genz
      #       Department of Mathematics
      #       Washington State University
      #       Pullman, WA 99164-3113
      #       Email : alangenz_AT_wsu.edu
      #
      #    This function is based on the method described by 
      #        Drezner, Z and G.O. Wesolowsky, (1989),
      #        On the computation of the bivariate normal integral,
      #        Journal of Statist. Comput. Simul. 35, pp. 101-107,
      #    with major modifications for double precision, and for |R| close to 1.
      #   
      # Original location:
      # * http://www.math.wsu.edu/faculty/genz/software/fort77/tvpack.f
      def cdf_genz(x,y,rho)
        dh=-x
        dk=-y
        r=rho
        twopi = 6.283185307179586
        
        w=11.times.collect {[nil]*4};
        x=11.times.collect {[nil]*4}
        
        data=[
        0.1713244923791705E+00, -0.9324695142031522E+00,
        0.3607615730481384E+00, -0.6612093864662647E+00,
        0.4679139345726904E+00, -0.2386191860831970E+00]
        
        (1..3).each {|i|
          w[i][1]=data[(i-1)*2]
          x[i][1]=data[(i-1)*2+1]
          
        }
        data=[
        0.4717533638651177E-01,-0.9815606342467191E+00,
        0.1069393259953183E+00,-0.9041172563704750E+00,
        0.1600783285433464E+00,-0.7699026741943050E+00,
        0.2031674267230659E+00,-0.5873179542866171E+00,
        0.2334925365383547E+00,-0.3678314989981802E+00,
        0.2491470458134029E+00,-0.1252334085114692E+00]
        (1..6).each {|i|
          w[i][2]=data[(i-1)*2]
          x[i][2]=data[(i-1)*2+1]

          
        }
        data=[
        0.1761400713915212E-01,-0.9931285991850949E+00,
        0.4060142980038694E-01,-0.9639719272779138E+00,
        0.6267204833410906E-01,-0.9122344282513259E+00,
        0.8327674157670475E-01,-0.8391169718222188E+00,
        0.1019301198172404E+00,-0.7463319064601508E+00,
        0.1181945319615184E+00,-0.6360536807265150E+00,
        0.1316886384491766E+00,-0.5108670019508271E+00,
        0.1420961093183821E+00,-0.3737060887154196E+00,
        0.1491729864726037E+00,-0.2277858511416451E+00,
        0.1527533871307259E+00,-0.7652652113349733E-01]
        
        (1..10).each {|i|
          w[i][3]=data[(i-1)*2]
          x[i][3]=data[(i-1)*2+1]

          
        }
        
        
        if ( r.abs < 0.3 )
          ng = 1
          lg = 3
        elsif ( r.abs < 0.75 )
          ng = 2
          lg = 6
        else 
          ng = 3
          lg = 10
        end
        
       
        h = dh
        k = dk 
        hk = h*k
        bvn = 0
        if ( r.abs < 0.925 )
          if ( r.abs > 0 )
            hs = ( h*h + k*k ).quo(2)
            asr = Math::asin(r)
            (1..lg).each do |i|
              [-1,1].each do |is|
                sn = Math::sin( asr *(  is * x[i][ng] + 1 ).quo(2) )
                bvn = bvn + w[i][ng] * Math::exp( ( sn*hk-hs ).quo( 1-sn*sn ) )
              end # do
            end # do
            bvn = bvn*asr.quo( 2*twopi )
          end # if
          bvn = bvn + Distribution::Normal.cdf(-h) * Distribution::Normal.cdf(-k)
          
          
        else # r.abs
          if ( r < 0 ) 
            k = -k
            hk = -hk
          end
          
          if ( r.abs < 1 ) 
            as = ( 1 - r )*( 1 + r )
            a = Math::sqrt(as)
            bs = ( h - k )**2
            c = ( 4 - hk ).quo(8) 
            d = ( 12 - hk ).quo(16)
            asr = -( bs.quo(as) + hk ).quo(2)
            if ( asr > -100 ) 
              bvn = a*Math::exp(asr) * ( 1 - c*( bs - as )*( 1 - d*bs.quo(5) ).quo(3) + c*d*as*as.quo(5) )
            end
            if ( -hk < 100 )
              b = Math::sqrt(bs)
              bvn = bvn - Math::exp( -hk.quo(2) ) * Math::sqrt(twopi)*Distribution::Normal.cdf(-b.quo(a))*b *
              ( 1 - c*bs*( 1 - d*bs.quo(5) ).quo(3) ) 
            end
            
            
            a = a.quo(2)
            (1..lg).each do |i|
              [-1,1].each do |is|
                xs = (a*(  is*x[i][ng] + 1 ) )**2
                rs = Math::sqrt( 1 - xs )
                asr = -( bs/xs + hk ).quo(2)
                if ( asr > -100 )
                  bvn = bvn + a*w[i][ng] * Math::exp( asr ) *
                    ( Math::exp( -hk*( 1 - rs ).quo(2*( 1 + rs ) ) ) .quo(rs) - ( 1 + c*xs*( 1 + d*xs ) ) )
                end
              end
            end
            bvn = -bvn/twopi
          end
          
          if ( r > 0 )
            bvn =  bvn + Distribution::Normal.cdf(-[h,k].max)
          else
            bvn = -bvn 
            if ( k > h ) 
              bvn = bvn + Distribution::Normal.cdf(k) - Distribution::Normal.cdf(h) 
            end
          end
        end
        bvn
      end
      private :f, :sgn 
    end
  end
end
