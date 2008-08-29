module RubySS
    # module for several statistical tests 
    module Test
        # Calculate chi square for two Matrix
        class << self
            def chi_square(real,expected)
                raise TypeError, "Both argument should be Matrix" unless real.is_a? Matrix and expected.is_a?Matrix
                sum=0
                (0...real.row_size).each {|row_i|
                    (0...real.column_size).each {|col_i|
                        val=((real[row_i,col_i].to_f - expected[row_i,col_i].to_f)**2) / expected[row_i,col_i].to_f
                        # p val
                        sum+=val
                    }
                }
                sum
            end
        end
    end
end
