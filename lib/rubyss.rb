# = rubyss.rb - 

# Process files and databases for statistical purposes, with focus on 
# estimation of parameters for several types of samples (simple random, 
# stratified and multistage sampling).
#
# Copyright (C) 2008 Claudio Bustos
#
# Claudio Bustos mailto:clbustos@gmail.com

$:.unshift(File.dirname(__FILE__))
require 'delegate'
require 'matrix'
require 'rubyss/vector'
class Numeric
  def square ; self * self ; end
end

module RubySS
	VERSION = '0.1.3'
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
