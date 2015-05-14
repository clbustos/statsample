#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'

Statsample::Analysis.store(Statsample::Dataset) do
  samples=1000
  a=Statsample::Vector.new_numeric(samples) {r=rand(5); r==4 ? nil: r}
  b=Statsample::Vector.new_numeric(samples) {r=rand(5); r==4 ? nil: r}

  ds={'a'=>a,'b'=>b}.to_dataset
  summary(ds)
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end

