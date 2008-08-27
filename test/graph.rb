require File.dirname(__FILE__)+"/../lib/rubyss"
require 'rbgsl'
v1=[1,2,3,4,6,20,2,20].to_vector
v1.type=:scale
v2=[5,5,6,6,7,7,2,1].to_vector
v2.type=:scale

GSL::Vector.graph(v1.gsl,v2.gsl)
