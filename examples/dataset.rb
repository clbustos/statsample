#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'

Statsample::Analysis.store(Daru::DataFrame) do
  samples=1000
  a=Statsample::Vector.new_with_size(samples) {r=rand(5); r==4 ? nil: r}
  b=Statsample::Vector.new_with_size(samples) {r=rand(5); r==4 ? nil: r}

  ds = Daru::DataFrame.new({:a=>a,:b=>b})
  summary(ds)
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end

