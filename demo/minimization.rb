#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'

d=Statsample::Minimization::Brent.new(-1,2  , proc {|x| (x+3)*(x-1)**2})

d.iterate
puts d.log
