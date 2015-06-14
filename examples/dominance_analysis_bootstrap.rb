#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'

Statsample::Analysis.store(Statsample::DominanceAnalysis::Bootstrap) do
  # Remember to call *update* after an assignment/deletion cycle if lazy_update
  # is *false*.
  Daru.lazy_update = true

  sample=300
  a=rnorm(sample)
  b=rnorm(sample)
  c=rnorm(sample)
  d=rnorm(sample)  
  a.rename :a
  b.rename :b
  c.rename :c
  d.rename :d
  
  ds = Daru::DataFrame.new({:a => a,:b => b,:cc => c,:d => d})
  attach(ds)
  ds[:y1] = a*5  + b*2 + cc*2 + d*2 + rnorm(sample,0,10)
  ds[:y2] = a*10 + rnorm(sample)
  
  dab=dominance_analysis_bootstrap(ds, [:y1,:y2], :debug=>true)
  dab.bootstrap(100,nil)
  summary(dab)
  ds2=ds[:a..:y1]
  dab2=dominance_analysis_bootstrap(ds2, :y1, :debug=>true)
  dab2.bootstrap(100,nil)
  summary(dab2)

  Daru.lazy_update = false
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end
