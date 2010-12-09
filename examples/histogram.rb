#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
$:.unshift('/home/cdx/dev/reportbuilder/lib/')

require 'benchmark'
require 'statsample'
n=1000
a=n.times.map {|i| rand()*20}.to_scale
hg=Statsample::Graph::Histogram.new(a, :bins=>15)

rb=ReportBuilder.new
rb.add(a.histogram)
rb.add(hg)
puts rb.to_text
