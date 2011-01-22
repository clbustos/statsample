#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'


Statsample::Analysis.store(Statsample::DominanceAnalysis) do
  sample=300
  a=rnorm(sample)
  b=rnorm(sample)
  c=rnorm(sample)
  d=rnorm(sample)
  
  ds={'a'=>a,'b'=>b,'cc'=>c,'d'=>d}.to_dataset
  attach(ds)
  ds['y']=a*5+b*3+cc*2+d+rnorm(300)  
  cm=cor(ds)
  summary(cm)
  lr=lr(ds,'y')
  summary(lr)
  da=dominance_analysis(ds,'y')
  summary(da)
  
  da=dominance_analysis(ds,'y',:name=>"Dominance Analysis using group of predictors", :predictors=>['a', 'b', %w{cc d}])
  summary(da)
end


if __FILE__==$0
  Statsample::Analysis.run_batch
end

