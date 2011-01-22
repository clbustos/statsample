#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'

Statsample::Analysis.store(Statsample::Graph::Histogram) do
  histogram(rnorm(3000,0,20))
end


if __FILE__==$0
   Statsample::Analysis.run
end
