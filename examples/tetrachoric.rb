#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'

Statsample::Analysis.store(Statsample::Bivariate::Tetrachoric) do
  
a=40
b=10
c=20
d=30
summary tetrachoric(a,b,c,d)
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end
