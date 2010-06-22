#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
require 'statsample/bivariate/tetrachoric'
samples=1000
variables=10
rng = GSL::Rng.alloc()
f1=samples.times.collect {rng.ugaussian()}.to_scale
f2=samples.times.collect {rng.ugaussian()}.to_scale
f3=samples.times.collect {rng.ugaussian()}.to_scale

vectors={}

variables.times do |i|
  vectors["v#{i}"]=samples.times.collect {|nv|  f1[nv]*(i-30)+f2[nv]*(i+30)+f3[nv]*(i+15) + rng.ugaussian() > 0 ? 1 : 0}.to_scale
end
ds=vectors.to_dataset

pa=Statsample::Factor::ParallelAnalysis.new(ds, :iterations=>10, :matrix_method=>:tetrachoric_correlation_matrix, :debug=>true)

pca=Statsample::Factor::PCA.new(Statsample::Bivariate.tetrachoric_correlation_matrix(ds))
rb=ReportBuilder.new(:name=>"Parallel Analysis with simulation") do |g|
  g.text("There are 3 real factors on data")
  g.parse_element(pca)
  g.text("Traditional Kaiser criterion (k>1) returns #{pca.m} factors")
  g.parse_element(pa)
  g.text("Parallel Analysis returns #{pa.number_of_factors} factors to preserve")
end

puts rb.to_text
