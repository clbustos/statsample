module Statsample
  # Module for several statistical tests
  
  module Test
    autoload(:UMannWhitney, 'statsample/test/umannwhitney')
    autoload(:Levene, 'statsample/test/levene')
    autoload(:T, 'statsample/test/t')
    autoload(:F, 'statsample/test/f')
    autoload(:ChiSquare, 'statsample/test/chisquare')
    autoload(:BartlettSphericity, 'statsample/test/bartlettsphericity')
    autoload(:KolmogorovSmirnov, 'statsample/test/kolmogorovsmirnov')
    autoload(:WilcoxonSignedRank, 'statsample/test/wilcoxonsignedrank')
    
    
    # Returns probability of getting a value lower or higher
    # than sample, using cdf and number of tails.
    # 
    # * <tt>:left</tt> : For one tail left, return the cdf
    # * <tt>:right</tt> : For one tail right, return 1-cdf
    # * <tt>:both</tt> : For both tails, returns 2*right_tail(cdf.abs)
    def p_using_cdf(cdf, tails=:both)
      tails=:both if tails==2 or tails==:two
      tails=:right if tails==1 or tails==:positive
      tails=:left if tails==:negative
      case tails
        when :left then cdf
        when :right then 1-cdf
        when :both 
          if cdf>=0.5
            cdf=1-cdf
          end
          2*cdf
      end
    end
    # Get critical t to create confidence interval 
    def t_critical(confidence_level, df)
      -Distribution::T.p_value((1-confidence_level) / 2.0, df)
    end
    # Get critical z to create confidence interval 
    def z_critical(confidence_level)
      -Distribution::Z.p_value((1-confidence_level) / 2.0)
    end
    
    extend self
    # Calculate chi square for two Matrix
    class << self
      def chi_square(observed, expected=nil)
        case observed
          when Vector
            ChiSquare::WithVector.new(observed,expected)
          when Matrix
            ChiSquare::WithMatrix.new(observed,expected)
          else
            raise "Not implemented for #{observed.class}"
        end
      end
      # Shorthand for Statsample::Test::UMannWhitney.new
      # 
      # * <tt>v1</tt> and <tt>v2</tt> should be Statsample::Vector.
      def u_mannwhitney(v1, v2)
        Statsample::Test::UMannWhitney.new(v1,v2)
      end
      # Shorthand for Statsample::Test::T::OneSample.new
      def t_one_sample(vector, opts=Hash.new)
        Statsample::Test::T::OneSample.new(vector,opts)
      end
      # Shorthand for Statsample::Test::T::TwoSamplesIndependent.new
      def t_two_samples_independent(v1,v2, opts=Hash.new)
        Statsample::Test::T::TwoSamplesIndependent.new(v1,v2,opts)
      end
      # Shorthand for Statsample::Test::WilcoxonSignedRank.new
	  def wilcoxon_signed_rank(v1,v2,opts=Hash.new)
		Statsample::Test::WilcoxonSignedRank.new(v1,v2,opts)
	  end
      # Shorthand for Statsample::Test::Levene.new
      def levene(input, opts=Hash.new)
        Statsample::Test::Levene.new(input,opts)
      end
      
    end
  end
end
