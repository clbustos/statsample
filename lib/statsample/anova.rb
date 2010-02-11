module Statsample
  module Anova
    # One Way Anova
    # Example:
    #   v1=[2,3,4,5,6].to_scale
    #   v2=[3,3,4,5,6].to_scale
    #   v3=[5,3,1,5,6].to_scale
    #   anova=Statsample::Anova::OneWay.new([v1,v2,v3])
    #   anova.f
    #   => 0.0243902439024391
    #   anova.significance
    #   => 0.975953044203438
    #   anova.sst 
    #   => 32.9333333333333
    #
    class OneWay
      def initialize(vectors)
        @vectors=vectors
      end
      # Total sum
      def sum
        @vectors.inject(0){|a,v| a+v.sum}
      end
      # Total mean
      def mean
        sum.quo(n)
      end
      # Total sum of squares
      def sst
        m=mean.to_f
        @vectors.inject(0) {|total,vector| total+vector.sum_of_squares(m) }
      end
      # Sum of squares within groups
      def sswg
        @vectors.inject(0) {|total,vector| total+vector.sum_of_squares }
      end
      # Sum of squares between groups
      def ssbg
        m=mean
        @vectors.inject(0) do |total,vector|
          total + (vector.mean-m).square * vector.size 
        end
      end
      # Degrees of freedom within groups
      def df_wg
          @vectors.inject(0) {|a,v| a+(v.size-1)}
      end
      # Degrees of freedom between groups 
      def df_bg
          @vectors.size-1
      end
      # Total Degrees of freedom
      def df_total
          n-1
      end
      # Total number of cases
      def n
          @vectors.inject(0){|a,v| a+v.size}
      end
      # Fisher
      def f
          k=@vectors.size
          (ssbg*(n-k)) / (sswg*(k-1))
      end
      # Significance of Fisher
      def significance
          1.0-Distribution::F.cdf(f,df_bg,df_wg)
      end
    end
  end
end
