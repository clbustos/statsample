#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
$:.unshift('/home/cdx/dev/reportbuilder/lib/')

require 'benchmark'
require 'statsample'
n=100

Statsample::Analysis.store(Statsample::Graph::Scatterplot) do
  x=rnorm(n)
  y=x+rnorm(n,0.5,0.2)
  scatterplot(x,y)
end

if __FILE__==$0
  Statsample::Analysis.run
end
