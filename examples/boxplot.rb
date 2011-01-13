#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'

ex=Statsample::Example.of(Statsample::Graph::Boxplot) do 
  n=100
  a=(n-1).times.map {|i| rand()*20+50}
  b=n.times.map {|i| rand()*10+50}.to_scale
  c=n.times.map {|i| rand()*5+50}.to_scale
   
  a.push(30)
  a=a.to_scale
  sp=Statsample::Graph::Boxplot.new(:vectors=>[a,b,c],:width=>300, :height=>300, :groups=>%w{first first second}, :minimum=>0)
  rb.add(sp)
end

if __FILE__==$0
  puts ex.rb.to_text
end
