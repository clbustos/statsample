#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
# == Description
#
# This example provides a small sneak-peak into creating a Daru::Vector.
# For details on using Daru::Vector (with example on math, statistics and plotting)
# see the notebook at this link: 
# http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/Data%20Analysis/Usage%20of%20Vector.ipynb
require 'statsample'

Statsample::Analysis.store(Daru::Vector) do
  a = Daru::Vector.new_with_size(1000) {r=rand(5); r==4 ? nil: r;}
  summary a
  b = Daru::Vector[1,2,3,4,6..10]
  summary b
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end
