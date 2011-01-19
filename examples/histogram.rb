#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'

ex=Statsample::Example.of(Statsample::Graph::Histogram) do
  n=3000
  
  rng=Distribution::Normal.rng_ugaussian
  a=n.times.map {|i| rng.call()*20}.to_scale
  hg=Statsample::Graph::Histogram.new(a, :bins=>20, :line_normal_distribution=>true )  
  
  rb.add(hg)
end


if __FILE__==$0
  puts ex.rb.to_text
end
