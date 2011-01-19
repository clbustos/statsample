#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'

ex=Statsample::Example.of(Statsample::Dataset) do

a=1000.times.collect {r=rand(5); r==4 ? nil: r;}.to_scale
b=1000.times.collect {r=rand(5); r==4 ? nil: r;}.to_scale

ds={'a'=>a,'b'=>b}.to_dataset
rb.add(ds)
end

if __FILE__==$0
  puts ex.rb.to_text
end

