#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
samples=100
variables=10
rng = GSL::Rng.alloc()
f1=samples.times.collect {rng.ugaussian()}.to_scale
f2=samples.times.collect {rng.ugaussian()}.to_scale

vectors={}

variables.times do |i|
  vectors["v#{i}"]=samples.times.collect {|nv|    
    if i<5
      f1[nv]*5 + f2[nv] *2 +rng.ugaussian()
    else
      f1[nv]*2 + f2[nv] *3 +rng.ugaussian()
    end
  }.to_scale
end
ds=vectors.to_dataset
cor=Statsample::Bivariate.correlation_matrix(ds)
map=Statsample::Factor::MAP.new(cor)
pca=Statsample::Factor::PCA.new(cor)

rb=ReportBuilder.new(:name=>"Velicer's MAP test") do |g|
  g.text("There are 2 real factors on data")
  g.parse_element(pca)
  g.text("Traditional Kaiser criterion (k>1) returns #{pca.m} factors")
  g.parse_element(map)
  g.text("Velicer's MAP Test returns #{map.number_of_factors} factors to preserve")
end

puts rb.to_text
