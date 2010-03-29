#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
a=40
b=10
c=20
d=30
tetra=Statsample::Bivariate::Tetrachoric.new(a,b,c,d)
puts tetra.summary
