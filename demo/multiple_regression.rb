#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
require 'benchmark'
samples=10000
a=samples.times.collect {rand}.to_scale
b=samples.times.collect {rand}.to_scale
c=samples.times.collect {rand}.to_scale
d=samples.times.collect {rand}.to_scale

ds={'a'=>a,'b'=>b,'c'=>c,'d'=>d}.to_dataset
ds['y']=ds.collect{|row| row['a']*5+row['b']*3+row['c']*2+row['d']*1+rand()}

Benchmark.bm(7) do |x|


rb=ReportBuilder.new("Multiple Regression Engines")

if HAS_GSL
  x.report("GSL:") {
  lr=Statsample::Regression::Multiple::GslEngine.new(ds,'y',:name=>"Multiple Regression using GSL")
  rb.add(lr.summary)
  }
end


if HAS_ALGIB
  x.report("Alglib:") {
  lr=Statsample::Regression::Multiple::AlglibEngine.new(ds,'y', :name=>"Multiple Regression using Alglib")
  rb.add(lr.summary)
  }
end
  x.report("Ruby:") {
  lr=Statsample::Regression::Multiple::RubyEngine.new(ds,'y',:name=>"Multiple Regression using RubyEngine")
  rb.add(lr.summary)
  }

  puts rb.to_text
end
