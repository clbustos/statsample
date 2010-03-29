#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib')
require 'statsample'
a=10.times.map {rand(100)}.to_scale
t_1=Statsample::Test.t_one_sample(a,{:u=>50})
puts t_1.summary

b=20.times.map {(rand(20))**2+50}.to_scale

t_2=Statsample::Test.t_two_samples_independent(a,b)
puts t_2.summary
