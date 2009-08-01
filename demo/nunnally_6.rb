require File.dirname(__FILE__)+'/../lib/rubyss'

x1=[7,12,15,10,19,13,10,12,15,14].to_vector(:scale)
x2=[9,6,8,8,9,8,6,8,10,9].to_vector(:scale)
x3=[7,15,13,9,12,12,13,11,9,10].to_vector(:scale)

puts RubySS::Bivariate.pearson(x1,x2)
puts RubySS::Bivariate.pearson(x2,x3)
puts RubySS::Bivariate.pearson(x1,x3)

puts "Residual x1.x3"
res1=RubySS::Bivariate.residuals(x1,x3)
puts res1
puts "Residual x2.x3"
res2=RubySS::Bivariate.residuals(x2,x3)
puts res2

puts "Residual x1.x2"
res3=RubySS::Bivariate.residuals(x1,x2)
puts res3
puts "Residual x3.x2"
res4=RubySS::Bivariate.residuals(x3,x2)
puts res4

puts "Partial correlation de 1 y 2, controlando 3"
puts RubySS::Bivariate.pearson(res1,res2)
puts RubySS::Bivariate.partial_correlation(x1,x2,x3)

puts "Partial correlation de 1 y 3, controlando 2"
puts RubySS::Bivariate.pearson(res3,res4)
puts RubySS::Bivariate.partial_correlation(x1,x3,x2)

puts "Partial correlation de 2 y 3, controlando 1"
puts RubySS::Bivariate.partial_correlation(x2,x3,x1)
