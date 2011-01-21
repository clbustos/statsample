#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
Statsample::Analysis.store(Statsample::Graph::Boxplot) do 
  n=30
  a=rnorm(n-1,50,10)
  b=rnorm(n, 30,5)
  c=rnorm(n,5,1)
  a.push(2)
  boxplot(:vectors=>[a,b,c],:width=>300, :height=>300, :groups=>%w{first first second}, :minimum=>0)
  
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end
