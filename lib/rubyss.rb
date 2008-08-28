# = rubyss.rb - 

# Process files and databases for statistical purposes, with focus on 
# estimation of parameters for several types of samples (simple random, 
# stratified and multistage sampling).
#
# Copyright (C) 2008 Claudio Bustos
#
# Claudio Bustos mailto:clbustos@gmail.com

$:.unshift(File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__)+"/../ext/optimization")
$:.unshift(File.dirname(__FILE__)+"/../ext/distributions")

require 'delegate'
require 'matrix'


class Numeric
  def square ; self * self ; end
end

# Process files and databases for statistical purposes, with focus on 
# estimation of parameters for several types of samples (simple random, 
# stratified and multistage sampling).

	begin
		require 'rbgsl'
		HAS_GSL=true
	rescue LoadError
		HAS_GSL=false
	end
    
    begin 
        require 'rubyssopt'
    rescue LoadError
        module RubySS
            OPTIMIZED=false
        end
    end
require 'rubyss/vector'
	
module RubySS
	
	VERSION = '0.1.4'
    class << self
		# Calculate chi square for two Matrix
        def matrix_chi_square(real,expected)
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

