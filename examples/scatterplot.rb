#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'benchmark'
require 'statsample'
n=100
a=n.times.map {|i| rand(10)+i}.to_scale
b=n.times.map {|i| rand(10)+i}.to_scale
sp=Statsample::Graph::Scatterplot.new(a,b, :width=>200, :height=>200)
rb=ReportBuilder.new do |b|
  b.parse_element(sp)
end  
puts rb.to_text
