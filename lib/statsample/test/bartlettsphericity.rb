module Statsample
  module Test
    # == Bartlett's test of Sphericity.
    # Test the hyphotesis that the sample correlation matrix
    # comes from a multivariate normal population where variables
    # are independent. In other words, the population correlation
    # matrix is the identity matrix.
    # == Reference
    # * Dziuban, C., & Shirkey E. (1974). When is a correlation matrix appropriate for factor analysis? Some decision rules. Psychological Bulletin, 81(6), 358-361.
    class BartlettSphericity
      include Statsample::Test
      include Summarizable
      attr_accessor :name
      attr_reader :ncases
      attr_reader :nvars
      attr_reader :value
      attr_reader :df
      # Args
      # * _matrix_: correlation matrix
      # * _ncases_: number of cases
      def initialize(matrix,ncases)
        @matrix=matrix
        @ncases=ncases
        @nvars=@matrix.row_size
        @name=_("Bartlett's test of sphericity")
        compute
      end
      # Uses SPSS formula.
      # On Dziuban & Shirkey, the minus between the first and second
      # statement is a *!!!
      # 
      def compute
        @value=-((@ncases-1)-(2*@nvars+5).quo(6))*Math::log(@matrix.determinant)
        @df=(@nvars*(@nvars-1)) / 2
      end
      def probability
        1-Distribution::ChiSquare.cdf(@value,@df)
      end
      def report_building(builder) # :nodoc:
        builder.text "%s : X(%d) = %0.4f , p = %0.4f" % [@name, @df, @value, probability]
      end
      
    end
  end
end
