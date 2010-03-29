#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
a=[1,2,3,4,5,6,7,8,100,10].to_scale
b=[30,40,50,60,70,80,90,100,110,120].to_scale

levene=Statsample::Test::Levene.new([a,b])
puts levene.summary
