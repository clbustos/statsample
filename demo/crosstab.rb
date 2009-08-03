require './../lib/statsample'
a=[1,1,1,1,1,1,1,2,2,2,2,2,3,3,3].to_vector
b=[1,2,3,2,2,2,1,1,1,2,2,1,2,2,3].to_vector

ct=Statsample::Crosstab.new(a,b)
puts ct.summary

