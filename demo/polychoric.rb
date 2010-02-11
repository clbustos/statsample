#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
#ct=Matrix[[58,52,1],[26,58,3],[8,12,9]]

ct=Matrix[[30,1,0,0,0,0],[0,10,2,0,0,0], [0,4,8,3,1,0], [0,3,3,37,9,0], [0,0,1, 25, 71, 49], [ 0,0,0,2, 20, 181]]
poly=Statsample::Bivariate::Polychoric.new(ct)

puts poly.summary

