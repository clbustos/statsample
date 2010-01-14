module Statsample
  module Test
    # U Mann-Whitney test
    # 
    class UMannWhitney
      attr_reader :r1, :r2, :u1, :u2, :u, :t
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
      def p
        if(@n1+@n2>30)
          (1-Distribution::Normal.cdf(z.abs()))*2
        else
          raise "Not implemented"
        end
      end
    end
  end
end