#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib')
require 'statsample'
samples=100
a=samples.times.map {rand(100)}.to_scale
ds=Statsample::Dataset.new
20.times do |i|
        ds["v#{i}"]=a.collect {|v| v+rand(20)}.to_scale
end
ds.update_valid_data
rel=Statsample::Reliability::ItemAnalysis.new(ds)
puts rel.summary
