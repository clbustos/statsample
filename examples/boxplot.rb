#!/usr/bin/ruby
# == Description
# 
# This example illustrates how daru, combined with Statsample::Graph::Boxplot
# can be used for generating box plots of a normally distributed set of data.
# 
# The 'rnorm' function, defined in statsample/shorthands generates a Daru::Vector
# object which contains the specified number of random variables in a normal distribution.
# It uses the 'distribution' gem for this purpose.
# 
# Create a boxplot of the data by specifying the vectors a, b and c and providing 
# necessary options to Statsample::Graph::Boxplot. The 'boxplot' function is shorthand
# for calling Statsample::Graph::Boxplot.
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
Statsample::Analysis.store(Statsample::Graph::Boxplot) do 
  n = 30
  a = rnorm(n-1,50,10)
  b = rnorm(n, 30,5)
  c = rnorm(n,5,1)
  a.push(2)

  boxplot(:vectors=>[a,b,c],:width=>300, :height=>300, :groups=>%w{first first second}, :minimum=>0)
end

if __FILE__==$0
  Statsample::Analysis.run
end
