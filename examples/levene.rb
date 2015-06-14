#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

# == Description
# 
# This example demonstrates how a levene test can be performed by
# using Daru::Vector and the Statsample::Test::Levene class.
# 
# Levene's test is an inferential statistic used to assess the
# equality of variances for a variable calculated for two or more groups.
# 
# == References
# 
# http://en.wikipedia.org/wiki/Levene%27s_test
require 'statsample'

Statsample::Analysis.store(Statsample::Test::Levene) do

  a = Daru::Vector.new([1,2,3,4,5,6,7,8,100,10])
  b = Daru::Vector.new([30,40,50,60,70,80,90,100,110,120])

  # The 'levene' function is used as a shorthand 
  # for creating a Statsample::Test::Levene object.
  summary(levene([a,b]))
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end
