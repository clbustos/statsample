require File.dirname(__FILE__)+'/../lib/rubyss'
require 'rbgsl'
require 'rubyss/resample'
require 'distributions/cdf'
require 'matrix'
ideal=Matrix[[30,30,40]]
tests=2000
monte=RubySS::Resample.repeat_and_save(tests) {
	observed=[0,0,0]
	(1..100).each{|i|
		r=rand(100)
		if r<30
			observed[0]+=1
		elsif r<60
			observed[1]+=1
		else
			observed[2]+=1
		end
	}
	(RubySS::matrix_chi_square(Matrix[observed],ideal)*100).round/100.to_f
}



v=monte.to_vector(:scale)
x=[]
y=[]
y2=[]
y3=[]
y4=[]
prev=0
prev_chi=0
v.frequencies.sort.each{|k,v|
	x.push(k)
	y.push(prev+v)
	prev=prev+v
	cdf_chi=CdfDistributions.chi_square_p(k,2)
	y2.push(cdf_chi*tests)
	y3.push(v*tests/100)
	#y3.push(0)
	delta=cdf_chi-prev_chi
	p delta*tests
	y4.push(delta*tests*20)
	p delta*tests*1000
	prev_chi=cdf_chi
}
GSL::graph(GSL::Vector.alloc(x), GSL::Vector.alloc(y),GSL::Vector.alloc(y2), GSL::Vector.alloc(y3), GSL::Vector.alloc(y4))
