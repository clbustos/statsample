#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'


a=100.times.collect {rand}.to_scale
b=100.times.collect {rand}.to_scale
c=100.times.collect {rand}.to_scale
d=100.times.collect {rand}.to_scale

ds={'a'=>a,'b'=>b,'c'=>c,'d'=>d}.to_dataset

ds['y']=ds.collect{|row| row['a']*5+row['b']*2+row['c']*2+row['d']*2+10*rand()}
dab=Statsample::DominanceAnalysis::Bootstrap.new(ds, 'y')
if HAS_GSL
  # Use Gsl if available (faster calculation)
  dab.regression_class=Statsample::Regression::Multiple::GslEngine
end
dab.bootstrap(100,nil,true)
puts dab.summary
