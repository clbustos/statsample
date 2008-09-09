#!/usr/bin/ruby

require 'rubyss'
require 'rubyss/resample'
require 'gnuplot'
require 'gsl'

v=[1]*50+[2]*100+[3]*120+[4]*150+[7]*100+[8]*70+[12]*30
v=v.to_vector(:scale)

tests=10000

Gnuplot.open do |gp|
			Gnuplot::Plot.new( gp ) do |plot|
			plot.boxwidth("0.9 absolute")
			plot.xrange("[-3:3]")
			plot.yrange("[0:1.1]")
			plot.style("fill  solid 1.00 border -1")
(20..20).each {|ss|
	sample_size=ss
	prom_s=[]
	monte=RubySS::Resample.repeat_and_save(tests) {
		sample=v.sample_with_replacement(sample_size)
		prom_s.push(sample.sds)
		sample.mean
	}
	xa=[]
	xy=[]
	xt=[]
	xz=[]
	m=monte.to_vector(:scale)
	sd_muestra=prom_s.to_vector(:scale).sds
	mx=m.mean
	er=v.sds / Math::sqrt(sample_size)
	er2=sd_muestra/ Math::sqrt(sample_size)

	prev=0
	m.frequencies.sort.each{|x,y|
		t=(x-mx)/(er2)
		xa.push(t)
		prev+=y
		xy.push(prev.to_f/tests)
		xt.push(GSL::Cdf.tdist_P(t,sample_size-1))
		xz.push(GSL::Cdf.tdist_P(t,20000))
	}
	plot.data << Gnuplot::DataSet.new( [xa,xy] ) do |ds|
		ds.with="lines"
		ds.title = "sim #{sample_size}"
	end
	plot.data << Gnuplot::DataSet.new( [xa,xt] ) do |ds|
		ds.with="lines"
		ds.title = "t #{sample_size}"
	end
	plot.data << Gnuplot::DataSet.new( [xa,xz] ) do |ds|
		ds.with="lines"
		ds.title = "z"
	end
	
}

end
end
	
