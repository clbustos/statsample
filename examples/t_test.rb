#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib')
require 'statsample'

Statsample::Analysis.store(Statsample::Test::T) do
  
  
  a=rnorm(10)
  t_1=Statsample::Test.t_one_sample(a,{:u=>50})
  summary t_1
  
  b=rnorm(10,2)
  
  t_2=Statsample::Test.t_two_samples_independent(a,b)
  summary t_2
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end
