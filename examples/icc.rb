#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
size=1000
a=size.times.map {rand(10)}.to_scale
b=a.recode{|i|i+rand(4)-2}
c=a.recode{|i|i+rand(4)-2}
d=a.recode{|i|i+rand(4)-2}
@ds={'a'=>a,'b'=>b,'c'=>c,'d'=>d}.to_dataset



@icc=Statsample::Reliability::ICC.new(@ds)

puts @icc.summary

@icc.type=:icc_3_1

puts @icc.summary


@icc.type=:icc_a_k

puts @icc.summary

