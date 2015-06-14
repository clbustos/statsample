#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

# == Description
# 
# This example shows how multiple regression can be performed using statsample and daru.
require 'statsample'

Statsample::Analysis.store(Statsample::Regression::Multiple) do

  samples=2000
  ds=dataset(:a => rnorm(samples),:b => rnorm(samples),:cc => rnorm(samples),:d => rnorm(samples))
  attach(ds)
  ds[:y] = a*5+b*3+cc*2+d+rnorm(samples)
  summary lr(ds,:y)
end

if __FILE__==$0
   Statsample::Analysis.run_batch
end
