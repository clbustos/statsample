#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib')
require 'statsample'
a=10.times.map {rand(100)}.to_scale
b=20.times.map {(rand(20))**2+50}.to_scale

u=Statsample::Test::UMannWhitney.new(a,b)
puts u.summary
