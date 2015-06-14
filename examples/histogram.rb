#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

# == Description
# 
# This example demonstrates how a histogram can be created 
# with statsample.
# 
# The 'histogram' function creates a histogram by using the 
# Statsample::Graph::Histogram class. This class accepts data 
# in a Daru::Vector (as created by `rnorm`).
# 
# A line showing normal distribution can be drawn by setting 
# the `:line_normal_distribution` option to *true*.
# 
# See this notebook for an illustration: 
# http://nbviewer.ipython.org/github/SciRuby/sciruby-notebooks/blob/master/statistics/Creating%20a%20Histogram.ipynb
require 'statsample'

Statsample::Analysis.store(Statsample::Graph::Histogram) do
  histogram(rnorm(3000,0,20), :line_normal_distribution => true)
end

if __FILE__==$0
   Statsample::Analysis.run
end
