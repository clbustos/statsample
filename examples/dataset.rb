#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
a=1000.times.collect {r=rand(5); r==4 ? nil: r;}.to_scale
b=1000.times.collect {r=rand(5); r==4 ? nil: r;}.to_scale

ds={'a'=>a,'b'=>b}.to_dataset
puts ds.summary
