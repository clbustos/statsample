#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
ct=Matrix[[58,52,1],[26,58,3],[8,12,9]]

# Fast estimation of polychoric correlation
poly=Statsample::Bivariate::Polychoric.new(ct,:debug=>true, :name=>"Polychoric with two-step")
puts poly.summary
puts poly.chi_square_model

# Uses polychoric series

poly=Statsample::Bivariate::Polychoric.new(ct, :method=>:polychoric_series, :name=>"Polychoric with polychoric series")
puts poly.summary

