require File.dirname(__FILE__)+'/../lib/rubyss'
require 'rbgsl'
require 'rubyss/resample'
require 'rubyss/test'
require 'matrix'
ideal=Matrix[[30,30,40]]
tests=10000
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
	RubySS::Test::chi_square(Matrix[observed],ideal)
}



v=monte.to_vector(:scale)

x=[]
y=[]
y2=[]
y3=[]
y4=[]
prev=0
prev_chi=0
v.frequencies.sort.each{|k,v1|
	x.push(k)
	y.push(prev+v1)
	prev=prev+v1
	cdf_chi=GSL::Cdf.chisq_P(k,2)
	y2.push(cdf_chi)
	y4.push(prev.quo(tests))
}


GSL::graph(GSL::Vector.alloc(x), GSL::Vector.alloc(y2), GSL::Vector.alloc(y4))
