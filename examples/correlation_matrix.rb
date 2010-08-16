#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'benchmark'
require 'statsample'
a=1000.times.collect {rand}.to_scale
b=1000.times.collect {rand}.to_scale
c=1000.times.collect {rand}.to_scale
d=1000.times.collect {rand}.to_scale
ds={'a'=>a,'b'=>b,'c'=>c,'d'=>d}.to_dataset
cm=Statsample::Bivariate.correlation_matrix(ds)
puts cm.summary
