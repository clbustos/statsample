module Statsample
  module Test
    #
    # = U Mann-Whitney test
    #
    # Non-parametric test for assessing whether two independent samples
    # of observations come from the same distribution.
    # 
    # == Assumptions
    #
    # * The two samples under investigation in the test are independent of each other and the observations within each sample are independent.
    # * The observations are comparable (i.e., for any two observations, one can assess whether they are equal or, if not, which one is greater).
    # * The variances in the two groups are approximately equal.
    #
    # Higher differences of distributions correspond to 
    # to lower values of U.
    #
    class UMannWhitney
      # Max for m*n allowed for exact calculation of probability
      MAX_MN_EXACT=10000
      
      # U sampling distribution, based on Dinneen & Blakesley (1973) algorithm.
      # This is the algorithm used on SPSS
      # Parameters:
      # * n1: group 1 size
      # * n2: group 2 size 
      # Reference: Dinneen, L., & Blakesley, B. (1973). Algorithm AS 62: A Generator for the Sampling Distribution of the Mann- Whitney U Statistic. Journal of the Royal Statistical Society, 22(2), 269-273
      # 
      def self.u_sampling_distribution_as62(n1,n2)

        freq=[]
        work=[]
        mn1=n1*n2+1
        max_u=n1*n2
        minmn=n1<n2 ? n1 : n2
        maxmn=n1>n2 ? n1 : n2
        n1=maxmn+1
        (1..n1).each{|i| freq[i]=1}
        n1+=1
        (n1..mn1).each{|i| freq[i]=0}
        work[1]=0
        xin=maxmn
        (2..minmn).each do |i|
          work[i]=0
          xin=xin+maxmn
          n1=xin+2
          l=1+xin.quo(2)
          k=i
          (1..l).each do |j|
            k=k+1
            n1=n1-1
            sum=freq[j]+work[j]
            freq[j]=sum
            work[k]=sum-freq[n1]
            freq[n1]=sum
          end
        end
        
        # Generate percentages for normal U
        dist=(1+max_u/2).to_i
        freq.shift
        total=freq.inject(0) {|a,v| a+v }
        (0...dist).collect {|i|
          if i!=max_u-i
            ues=freq[i]*2
          else
            ues=freq[i]
          end
          ues.quo(total)
        }
      end
      
      # Generate distribution for permutations. 
      # Very expensive, but useful for demostrations
      
      def self.distribution_permutations(n1,n2)
        base=[0]*n1+[1]*n2
        po=Statsample::Permutation.new(base)
        upper=0
        total=n1*n2
        req={}
        po.each do |perm|
          r0,s0=0,0
          perm.each_index {|c_i|
            if perm[c_i]==0
              r0+=c_i+1
              s0+=1
            end
          }
          u1=r0-((s0*(s0+1)).quo(2))
          u2=total-u1
          temp_u= (u1 <= u2) ? u1 : u2
          req[perm]=temp_u
        end
        req
      end
      # Sample 1 Rank sum
      attr_reader :r1
      # Sample 2 Rank sum
      attr_reader :r2
      # Sample 1 U
      attr_reader :u1
      # Sample 2 U
      attr_reader :u2
      # U Value
      attr_reader :u
      # Compensation for ties
      attr_reader :t
      def initialize(v1,v2)
        @n1=v1.valid_data.size
        @n2=v2.valid_data.size

        data=(v1.valid_data+v2.valid_data).to_scale
        groups=(([0]*@n1)+([1]*@n2)).to_vector
        ds={'g'=>groups, 'data'=>data}.to_dataset
        @t=nil
        @ties=data.data.size!=data.data.uniq.size        
        if(@ties)
          adjust_for_ties(ds['data'])
        end
        ds['ranked']=ds['data'].ranked(:scale)
        
        @n=ds.cases
          
        @r1=ds.filter{|r| r['g']==0}['ranked'].sum
        @r2=((ds.cases*(ds.cases+1)).quo(2))-r1
        @u1=r1-((@n1*(@n1+1)).quo(2))
        @u2=r2-((@n2*(@n2+1)).quo(2))
        @u=(u1<u2) ? u1 : u2
      end
      def summary
        out=<<-HEREDOC
Mann-Whitney U
Sum of ranks v1: #{@r1.to_f}
Sum of ranks v1: #{@r2.to_f}
U Value: #{@u.to_f}
Z: #{sprintf("%0.3f",z)} (p: #{sprintf("%0.3f",z_probability)})
        HEREDOC
        if @n1*@n2<MAX_MN_EXACT
          out+="Exact p (Dinneen & Blakesley): #{sprintf("%0.3f",exact_probability)}"
        end
          out
      end
      # Exact probability of finding values of U lower or equal to sample on U distribution. Use with caution with m*n>100000
      # Reference: Dinneen & Blakesley (1973)
      def exact_probability
        dist=UMannWhitney.u_sampling_distribution_as62(@n1,@n2)
        sum=0
        (0..@u.to_i).each {|i|
          sum+=dist[i]
        }
        sum
      end
      # Reference: http://europe.isixsigma.com/library/content/c080806a.asp
      def adjust_for_ties(data)
        @t=data.frequencies.find_all{|k,v| v>1}.inject(0) {|a,v|
          a+(v[1]**3-v[1]).quo(12)
        }        
      end
      # Z value for U, with adjust for ties.
      # For large samples, U is approximately normally distributed. 
      # In that case, you can use z to obtain probabily for U.
      # Reference: SPSS Manual
      def z
        mu=(@n1*@n2).quo(2)
        if(!@ties)
          ou=Math::sqrt(((@n1*@n2)*(@n1+@n2+1)).quo(12))
        else
          n=@n1+@n2
          first=(@n1*@n2).quo(n*(n-1))
          second=((n**3-n).quo(12))-@t
          ou=Math::sqrt(first*second)
        end
        (@u-mu).quo(ou)
      end
      # Assuming H_0, the proportion of cdf with values of U lower
      # than the sample. 
      # Use with more than 30 cases per group.
      def z_probability
        (1-Distribution::Normal.cdf(z.abs()))*2
      end
    end
      
  end
end