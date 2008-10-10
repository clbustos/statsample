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

#
# :startdoc:
#
module RubySS
    VERSION = '0.1.7'
    SPLIT_TOKEN = ","
	module Util
		class << self
		def chart_gdchart(file,width,height,chart_type, labels, options,num_datasets,data)
				require 'GDChart'
				gdc=GDChart.new
				gdc.title="Generic title"
				gdc.bg_color=0xFFFFFF
				gdc.image_type=GDChart::JPEG
				options.each{|k,v|
					gdc.send(k+"=",v)
				}
				f=File.open(file,"w") {|f|
					gdc.out_graph(width,height,f,chart_type, data.length/num_datasets,labels,num_datasets,data)
				}
		end
		end
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


require 'rubyss/vector'
require 'rubyss/dataset'
require 'rubyss/resample'
require 'rubyss/converters'
require 'rubyss/crosstab'
