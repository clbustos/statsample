#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
$:.unshift('/home/cdx/dev/reportbuilder/lib/')

require 'benchmark'
require 'statsample'
n=1000
a=n.times.map {|i| rand()*100}.to_scale
hg=Statsample::Graph::Histogram.new(a, :bins=>5)

rb=ReportBuilder.new
rb.add(hg)
rb.save_html('histo.html')
