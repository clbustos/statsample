#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib')
require 'statsample'

Statsample::Analysis.store(Statsample::Test::UMannWhitney) do

  a=10.times.map {rand(100)}.to_scale
  b=20.times.map {(rand(20))**2+50}.to_scale

  u=Statsample::Test::UMannWhitney.new(a,b)
  summary u
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end
