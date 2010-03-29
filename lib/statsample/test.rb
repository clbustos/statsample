module Statsample
  # Module for several statistical tests
  
  module Test
    autoload(:UMannWhitney, 'statsample/test/umannwhitney')
    autoload(:Levene, 'statsample/test/levene')
    autoload(:T, 'statsample/test/t')
    
    # Returns probability of getting a value lower or higher
    # than sample, using cdf and number of tails.
    # * For one tail left, return the cdf
    # * For one tail right, return 1-cdf
    # * For two tails, returns 2*right_tail(cdf.abs)
    def p_using_cdf(cdf, tails=:both)
      tails=:both if tails==2
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
    extend self
    # Calculate chi square for two Matrix
    class << self
      def chi_square(real,expected)
        sum=0
        (0...real.row_size).each {|row_i|
          (0...real.column_size).each {|col_i|
            val=((real[row_i,col_i].to_f - expected[row_i,col_i].to_f)**2) / expected[row_i,col_i].to_f
            # puts "Real: #{real[row_i,col_i].to_f} ; esperado: #{expected[row_i,col_i].to_f}"
# puts "Diferencial al cuadrado: #{(real[row_i,col_i].to_f - expected[row_i,col_i].to_f)**2}"
            sum+=val
          }
        }
        sum
      end
      def u_mannwhitney(v1p,v2p)
        Statsample::Test::UMannWhitney.new(v1p,v2p)
      end
      # Shorthand for Statsample::Test::T::OneSample.new
      def t_one_sample(vector, opts=Hash.new)
        Statsample::Test::T::OneSample.new(vector,opts)
      end
      # Shorthand for Statsample::Test::T::TwoSamplesIndependent.new
      def t_two_samples_independent(v1,v2, opts=Hash.new)
        Statsample::Test::T::TwoSamplesIndependent.new(v1,v2,opts)
      end

      # Shorthand for Statsample::Test::Levene.new
      def levene(input, opts=Hash.new)
        Statsample::Test::Levene.new(input,opts)
      end
      
    end
  end
end
