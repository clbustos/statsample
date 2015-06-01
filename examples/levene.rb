#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'

Statsample::Analysis.store(Statsample::Test::Levene) do

  a = Daru::Vector.new([1,2,3,4,5,6,7,8,100,10])
  b = Daru::Vector.new([30,40,50,60,70,80,90,100,110,120])
  summary(levene([a,b]))
end

if __FILE__==$0
   Statsample::Analysis.run_batch
end
