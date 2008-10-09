# = rubyss.rb - 

# Process files and databases for statistical purposes, with focus on 
# estimation of parameters for several types of samples (simple random, 
# stratified and multistage sampling).
#
# Copyright (C) 2008 Claudio Bustos
#
# Claudio Bustos mailto:clbustos@gmail.com

# :stopdoc:

$:.unshift(File.dirname(__FILE__))
$:.unshift(File.expand_path(File.dirname(__FILE__)+"/../ext"))

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
       require 'rubyss/rubyssopt'
    rescue LoadError
        module RubySS
            OPTIMIZED=false
        end
    end
require 'rubyss/vector'
require 'rubyss/dataset'
require 'rubyss/resample'
require 'rubyss/converters'
require 'rubyss/crosstab'
#
# :startdoc:
#
module RubySS
    VERSION = '0.1.7'
    SPLIT_TOKEN = ","
	module Util
		# Finite population correction
        # Source: Cochran(1972)
        def fpc(sam,pop)
            ((pop - sam).to_f / ( pop - 1))
        end
        # 1 - sample fraction
        def qf(sam,pop)
            1-(sam.to_f/pop)
        end
	end    
end
