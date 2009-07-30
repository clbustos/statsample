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


def create_test(*args,&proc) 
    description=args.shift
    fields=args
    [description, fields, Proc.new]
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
        require 'alglib'
        HAS_ALGIB=true
    rescue LoadError
        HAS_ALGIB=false
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
    VERSION = '0.1.9'
    SPLIT_TOKEN = ","
	autoload(:Database, 'rubyss/converters')
    autoload(:Anova, 'rubyss/anova')
	autoload(:CSV, 'rubyss/converters')
	autoload(:Excel, 'rubyss/converters')
	autoload(:GGobi, 'rubyss/converters')
    autoload(:DominanceAnalysis, 'rubyss/doman')
	autoload(:HtmlReport, 'rubyss/htmlreport')
    autoload(:Mx, 'rubyss/converters')
	autoload(:Resample, 'rubyss/resample')
	autoload(:SRS, 'rubyss/srs')
	autoload(:Codification, 'rubyss/codification')
	autoload(:Reliability, 'rubyss/reliability')
	autoload(:Bivariate, 'rubyss/bivariate')
	autoload(:Multivariate, 'rubyss/multivariate')

	autoload(:Regression, 'rubyss/regression')
	autoload(:Test, 'rubyss/test')
	module Util
        # Reference: http://www.itl.nist.gov/div898/handbook/eda/section3/normprpl.htm
        def normal_order_statistic_medians(i,n)
            if i==1
                u= 1.0 - normal_order_statistic_medians(n,n)
            elsif i==n
                u=0.5**(1 / n.to_f)
            else
                u= (i - 0.3175) / (n + 0.365)
            end
            u
        end
	end
end

require 'rubyss/vector'
require 'rubyss/dataset'
require 'rubyss/crosstab'



