#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
sample=200
a=sample.times.collect {rand}.to_scale
b=sample.times.collect {rand}.to_scale
c=sample.times.collect {rand}.to_scale
d=sample.times.collect {rand}.to_scale

ds={'a'=>a,'b'=>b,'c'=>c,'d'=>d}.to_dataset
ds['y']=ds.collect{|row| row['a']*5+row['b']*3+row['c']*2+row['d']+rand()}
rb=ReportBuilder.new("Dominance Analysis")

cm=Statsample::Bivariate.correlation_matrix(ds)
rb.add(cm)
lr=Statsample::Regression::Multiple::RubyEngine.new(ds,'y')
rb.add(lr)

#da=Statsample::DominanceAnalysis.new(ds,'y')
#rb.add(da)

da=Statsample::DominanceAnalysis.new(ds,'y',:name=>"Dominance Analysis using group of predictors", :predictors=>['a', 'b', %w{c d}])
rb.add(da)


puts rb.to_text
