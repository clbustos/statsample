#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'


a=100.times.collect {rand}.to_scale
b=100.times.collect {rand}.to_scale
c=100.times.collect {rand}.to_scale
d=100.times.collect {rand}.to_scale

a.name="a"
b.name="b"
c.name="c"
d.name="d"

ds={'a'=>a,'b'=>b,'c'=>c,'d'=>d}.to_dataset

ds['y1']=ds.collect{|row| row['a']*5+row['b']*2+row['c']*2+row['d']*2+10*rand()}
ds['y2']=ds.collect{|row| row['a']*10+rand()}

dab=Statsample::DominanceAnalysis::Bootstrap.new(ds, ['y1','y2'], :debug=>true)
dab.bootstrap(100,nil)
puts dab.summary
ds2=ds['a'..'y1']
dab=Statsample::DominanceAnalysis::Bootstrap.new(ds2, 'y1', :debug=>true)
dab.bootstrap(100,nil)
puts dab.summary
