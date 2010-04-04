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
    #   anova.probability
    #   => 0.975953044203438
    #   anova.sst 
    #   => 32.9333333333333
    #
    class OneWay < Statsample::Test::F
      def initialize(vectors,opts=Hash.new)
        @vectors=vectors
        opts_default={:name=>_("Anova One-Way"), :name_numerator=>"Between Groups", :name_denominator=>"Within Groups"}
        super(ssbg,sswg, df_bg, df_wg)
      end
      # Total mean
      def mean
        sum=@vectors.inject(0){|a,v| a+v.sum}
        sum.quo(n)
      end
      
      # Total sum of squares
      def sst
        m=mean
        @vectors.inject(0) {|total,vector| total+vector.ss(m) }
      end
      # Sum of squares within groups
      def sswg
        @sswg||=@vectors.inject(0) {|total,vector| total+vector.ss }
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
        @dk_wg||=n-k
      end
      def k
        @k||=@vectors.size
      end
      # Degrees of freedom between groups 
      def df_bg
          k-1
      end
      # Total number of cases
      def n
          @vectors.inject(0){|a,v| a+v.size}
      end
      
    end
  end
end
