#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
a=1000.times.collect {rand}.to_scale
b=1000.times.collect {rand}.to_scale
c=1000.times.collect {rand}.to_scale
ds={'a'=>a,'b'=>b,'c'=>c}.to_dataset
ds['y']=ds.collect{|row| row['a']*5+row['b']*3+row['c']*2+rand()}
da=Statsample::DominanceAnalysis.new(ds,'y')
puts da.summary
