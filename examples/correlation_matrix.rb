#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'

Statsample::Analysis.store("Statsample::Bivariate.correlation_matrix") do
  samples=1000
  ds=data_frame(
    'a'=>rnorm(samples),
    'b'=>rnorm(samples),
    'c'=>rnorm(samples),
    'd'=>rnorm(samples))
  cm=cor(ds)
  summary(cm)
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end

