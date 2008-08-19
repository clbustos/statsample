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
require 'rubyss/vector'
class Numeric
  def square ; self * self ; end
end

module RubySS
	VERSION = '0.1.3'
end


