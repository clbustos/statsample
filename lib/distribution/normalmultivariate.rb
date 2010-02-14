module Distribution
    # Calculate cdf and inverse cdf for Multivariate Distribution.
    module NormalMultivariate
      class << self
        # Returns multivariate cdf distribution
        # * a is the array of lower values
        # * b is the array of higher values
        # * s is an symmetric positive definite covariance matrix
        def cdf(aa,bb,sigma, epsilon=0.0001, alpha=2.5, max_iterations=100) # :nodoc:
          raise "Doesn't work yet"
          a=[nil]+aa
          b=[nil]+bb
          m=aa.size
          sigma=sigma.to_gsl if sigma.respond_to? :to_gsl
          
          cc=GSL::Linalg::Cholesky.decomp(sigma)
          c=cc.lower
          intsum=0
          varsum=0
          n=0
          d=Array.new(m+1,nil)
          e=Array.new(m+1,nil)
          f=Array.new(m+1,nil)
          (1..m).each {|i|
            d[i]=0.0 if a[i].nil?
            e[i]=1.0 if b[i].nil?
          }
          d[1]=uPhi(a[1].quo( c[0,0])) unless d[1]==0
          e[1]=uPhi(b[1].quo( c[0,0])) unless e[1]==1
          f[1]=e[1]-d[1]

          error=1000
          begin 
            w=(m+1).times.collect {|i| rand*epsilon}
            y=[]
            (2..m).each do |i|
              y[i-1]=iPhi(d[i-1] + w[i-1] * (e[i-1] - d[i-1]))
              sumc=0
              (1..(i-1)).each do |j|
                sumc+=c[i-1, j-1]*y[j]
              end
              
              if a[i]!=nil
                d[i]=uPhi((a[i]-sumc).quo(c[i-1,i-1]))
              end
             # puts "sumc:#{sumc}"
              
              if b[i]!=nil
                #puts "e[#{i}] :#{c[i-1,i-1]}"
                e[i]=uPhi((b[i]-sumc).quo(c[i-1, i-1]))
              end
              f[i]=(e[i]-d[i])*f[i-1]
            end
            intsum+=intsum+f[m]
            varsum=varsum+f[m]**2
            n+=1
            error=alpha*Math::sqrt((varsum.quo(n) - (intsum.quo(n))**2).quo(n))
            end while(error>epsilon and n<max_iterations)
          
            f=intsum.quo(n)
          #p intsum
          #puts "f:#{f}, n:#{n}, error:#{error}"
          f
        end
        def iPhi(pr)
          Distribution::Normal.p_value(pr)
        end
        def uPhi(x)
          Distribution::Normal.cdf(x)
        end
      end
    end
end
