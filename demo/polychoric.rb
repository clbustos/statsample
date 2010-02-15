#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
ct=Matrix[[58,52,1],[26,58,3],[8,12,9]]

# Estimation of polychoric correlation using two-step (default)
poly=Statsample::Bivariate::Polychoric.new(ct, :name=>"Polychoric with two-step")
puts poly.summary


# Estimation of polychoric correlation using joint method (slow)
poly=Statsample::Bivariate::Polychoric.new(ct, :method=>:joint, :name=>"Polychoric with joint")
puts poly.summary


# Uses polychoric series (not recomended)

poly=Statsample::Bivariate::Polychoric.new(ct, :method=>:polychoric_series, :name=>"Polychoric with polychoric series")
puts poly.summary

