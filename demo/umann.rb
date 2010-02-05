require File.dirname(__FILE__)+'/../lib/statsample'
v1=[1,2,3,4,7,8,9,10,14,15].to_scale
v2=[5,6,11,12,13,16,17,18,19].to_scale
u=Statsample::Test::UMannWhitney.new(v1,v2)

puts u.summary

#p Statsample::Test::UMannWhitney.exact_probability_as62(100,100)
