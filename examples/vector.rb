#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
a=1000.times.collect {r=rand(5); r==4 ? nil: r;}.to_scale
puts a.summary
