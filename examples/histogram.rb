#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
$:.unshift('/home/cdx/dev/reportbuilder/lib/')
require 'statsample'
n=3000
rng=Distribution::Normal.rng_ugaussian
a=n.times.map {|i| rng.call()*20}.to_scale
hg=Statsample::Graph::Histogram.new(a, :bins=>20, :line_normal_distribution=>true )

rb=ReportBuilder.new
#rb.add(a.histogram)
rb.add(hg)
rb.save_html('histogram.html')
