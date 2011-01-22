#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
samples=150
variables=30
iterations=50
Statsample::Analysis.store(Statsample::Factor::ParallelAnalysis) do 
  
rng = Distribution::Normal.rng_ugaussian()
f1=rnorm(samples)
f2=rnorm(samples)
f3=rnorm(samples)

vectors={}

variables.times do |i|
  vectors["v#{i}"]=samples.times.collect {|nv| f1[nv]*i+(f2[nv]*(15-i))+((f3[nv]*(30-i))*1.5)*rng.call}.to_scale
  vectors["v#{i}"].name="Vector #{i}"
end

  ds=vectors.to_dataset

  pa=Statsample::Factor::ParallelAnalysis.new(ds, :iterations=>iterations, :debug=>true)
  pca=pca(cor(ds))
  echo "There are 3 real factors on data"
  summary pca
  echo "Traditional Kaiser criterion (k>1) returns #{pca.m} factors"
  summary pa
  echo "Parallel Analysis returns #{pa.number_of_factors} factors to preserve"
end

if __FILE__==$0
   Statsample::Analysis.run_batch
end
