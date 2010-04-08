#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
samples=100
variables=30
rng = GSL::Rng.alloc()
f1=samples.times.collect {rng.ugaussian()}.to_scale
f2=samples.times.collect {rng.ugaussian()}.to_scale
f3=samples.times.collect {rng.ugaussian()}.to_scale

vectors={}

variables.times do |i|
  vectors["v#{i}"]=samples.times.collect {|nv| f1[nv]*i+(f2[nv]*(15-i))+((f3[nv]*(30-i))*1.5)*rng.ugaussian()}.to_scale
end
ds=vectors.to_dataset

pa=Statsample::Factor::ParallelAnalysis.new(ds, :iterations=>100, :debug=>true)
pca=Statsample::Factor::PCA.new(Statsample::Bivariate.correlation_matrix(ds))
rb=ReportBuilder.new(:name=>"Parallel Analysis with simulation") do |g|
  g.text("There are 3 real factors on data")
  g.parse_element(pca)
  g.text("Traditional Kaiser criterion (k>1) returns #{pca.m} factors")
  g.parse_element(pa)
  g.text("Parallel Analysis returns #{pa.number_of_factors} factors to preserve")
end

puts rb.to_text
