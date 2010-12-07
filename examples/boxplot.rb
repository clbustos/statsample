#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
$:.unshift('/home/cdx/dev/reportbuilder/lib/')

require 'benchmark'
require 'statsample'
n=100
a=(n-1).times.map {|i| rand()*20+50}
b=n.times.map {|i| rand()*10+50}.to_scale
c=n.times.map {|i| rand()*5+50}.to_scale
 
a.push(30)
a=a.to_scale
sp=Statsample::Graph::Boxplot.new(:vectors=>[a,b,c],:width=>300, :height=>300, :groups=>%w{first first second}, :minimum=>0)
rb=ReportBuilder.new
rb.add(sp)
puts rb.to_text
