#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
$:.unshift('/home/cdx/dev/reportbuilder/lib/')

# == Description
#
# Creating a scatterplot with statsample's Statsample::Graph::Scatterplot class.
# 
# In this example we'll demonstrate how a normally distributed Daru::Vector can
# be created using the daru and distribution gems, and how the values generated
# can be plotted very easily using the 'scatterplot' shorthand and supplying X
# and Y co-ordinates.
require 'benchmark'
require 'statsample'
n=100

Statsample::Analysis.store(Statsample::Graph::Scatterplot) do
  x=rnorm(n)
  y=x+rnorm(n,0.5,0.2)
  scatterplot(x,y)
end

if __FILE__==$0
  Statsample::Analysis.run
end
