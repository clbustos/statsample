module Statsample
  module Test
    module ChiSquare
      class WithMatrix
        attr_reader :df
        attr_reader :value
        def initialize(observed, expected=nil)
          @observed=observed
          @expected=expected or calculate_expected
          raise "Observed size!=expected size" if @observed.row_size!=@expected.row_size or @observed.column_size!=@expected.column_size
          @df=(@observed.row_size-1)*(@observed.column_size-1)
          @value=compute_chi
        end
        def calculate_expected
          sum=@observed.total_sum
          @expected=Matrix.rows( @observed.row_size.times.map {|i|
            @observed.column_size.times.map {|j|
              (@observed.row_sum[i].quo(sum) * @observed.column_sum[j].quo(sum))*sum
            }
          })          
        end
        def to_f
          @value
        end
        def chi_square
          @value
        end
        def probability
          1-Distribution::ChiSquare.cdf(@value.to_f,@df)
        end
        def compute_chi
            sum=0
            (0...@observed.row_size).each {|i|
              (0...@observed.column_size).each {|j|
              sum+=((@observed[i, j] - @expected[i,j])**2).quo(@expected[i,j])
              }
            }
            sum
        end
      end
    end
  end
end