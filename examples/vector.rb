#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'

Statsample::Analysis.store(Statsample::Vector) do

  a=Statsample::Vector.new_scale(1000) {r=rand(5); r==4 ? nil: r;}
  summary a
  b=c(1,2,3,4,6..10)
  summary b
  
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end
