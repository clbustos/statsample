#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'


ex=Statsample::Example.of(Statsample::DominanceAnalysis) do
  sample=300
  a=Statsample::Vector.new_scale(sample) {rand}
  b=Statsample::Vector.new_scale(sample) {rand}
  c=Statsample::Vector.new_scale(sample) {rand}
  d=Statsample::Vector.new_scale(sample) {rand}
  
  ds={'a'=>a,'b'=>b,'c'=>c,'d'=>d}.to_dataset
  ds['y']=ds.collect{|row| row['a']*5 + row['b']*3 + row['c']*2 + row['d'] + rand()}
  
  cm=Statsample::Bivariate.correlation_matrix(ds)
  rb.add(cm)
  lr=Statsample::Regression::Multiple::RubyEngine.new(ds,'y')
  rb.add(lr)
  da=Statsample::DominanceAnalysis.new(ds,'y')
  rb.add(da)
  
  da=Statsample::DominanceAnalysis.new(ds,'y',:name=>"Dominance Analysis using group of predictors", :predictors=>['a', 'b', %w{c d}])
  rb.add(da)
end


if __FILE__==$0
  puts ex.rb.to_text
end

