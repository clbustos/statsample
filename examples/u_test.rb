#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib')

# == Description
#
# Example illustrating Mann-Whitney U test with statsample.
#
# == References
# 
# http://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test
require 'statsample'

Statsample::Analysis.store(Statsample::Test::UMannWhitney) do

  a = Daru::Vector.new(10.times.map {rand(100)})
  b = Daru::Vector.new(20.times.map {(rand(20))**2+50})

  u=Statsample::Test::UMannWhitney.new(a,b)
  summary u
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end
