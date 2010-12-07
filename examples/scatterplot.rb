#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
$:.unshift('/home/cdx/dev/reportbuilder/lib/')

require 'benchmark'
require 'statsample'
n=100
a=n.times.map {|i| rand(10)+i}.to_scale
b=n.times.map {|i| rand(10)+i}.to_scale
sp=Statsample::Graph::Scatterplot.new(a,b, :width=>200, :height=>200)
rb=ReportBuilder.new
rb.add(sp)
puts rb.to_text
