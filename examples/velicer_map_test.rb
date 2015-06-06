#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
# == Description
#
# Velicer MAP test.

require 'statsample'

Statsample::Analysis.store(Statsample::Factor::MAP) do
  
  rng=Distribution::Normal.rng
  samples=100
  variables=10
  
  f1=rnorm(samples)
  f2=rnorm(samples)
  
  vectors={}
  
  variables.times do |i|
  vectors["v#{i}".to_sym]= Daru::Vector.new(
    samples.times.collect do |nv|    
      if i<5
        f1[nv]*5 + f2[nv] *2 +rng.call
      else
        f1[nv]*2 + f2[nv] *3 +rng.call
      end
    end)
  end
  
  
  ds = Daru::DataFrame.new(vectors)
  cor=cor(ds)
  pca=pca(cor)
  
  map=Statsample::Factor::MAP.new(cor)
  
  echo ("There are 2 real factors on data")
  summary(pca)
  echo("Traditional Kaiser criterion (k>1) returns #{pca.m} factors")
  summary(map)
  echo("Velicer's MAP Test returns #{map.number_of_factors} factors to preserve")
end
if __FILE__==$0
  Statsample::Analysis.run_batch
end
