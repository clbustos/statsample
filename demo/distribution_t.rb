#!/usr/bin/ruby

require File.dirname(__FILE__)+"/../lib/rubyss"
require 'rubyss/resample'
require 'gnuplot'
r = GSL::Rng.alloc(GSL::Rng::TAUS, 1)
v=[]
population_size=10000
population_size.times{|i|
    v.push(r.ugaussian)
}

v=v.to_vector(:scale)
vm=v.mean
vsd=v.sdp
puts "Population sd:#{v.sdp}"
tests=3000
Gnuplot.open do |gp|
			Gnuplot::Plot.new( gp ) do |plot|
			plot.boxwidth("0.9 absolute")
			plot.xrange("[-3:3]")
			plot.yrange("[0:1.1]")
			plot.style("fill  solid 1.00 border -1")
[2].each {|ss|
    puts "Sample size:#{ss}"
    ee=v.sdp.quo(Math::sqrt(ss))
    puts "SE: #{ee}"

    puts "Expected variance with replacement: #{v.variance_population.quo(ss)*(v.size-1).quo(v.size)}"
    puts "Expected variance without replacement: #{v.variance_population.quo(ss)*(1-ss.quo(v.size))}"
    
	sample_size=ss
    sds_prom=[]
    sds_prom_wo=[]
	monte_wr=RubySS::Resample.repeat_and_save(tests) {
		sample=v.sample_with_replacement(sample_size)
        sds_prom.push(sample.sds)
		sample.mean
	}
    monte_wor=RubySS::Resample.repeat_and_save(tests) {
		sample=v.sample_without_replacement(sample_size)
        sds_prom_wo.push(sample.sds)
		sample.mean
	}
    xxz=[]
    xxt=[]
	xa=[]
	xy=[]
	xt=[]
	xz=[]
    
    s_wr=sds_prom.to_vector(:scale).mean
    s_wor=sds_prom_wo.to_vector(:scale).mean

	mw=monte_wr.to_vector(:scale)
    mwo=monte_wor.to_vector(:scale)
    puts "Sample variance with replacement: #{mw.variance_population}"
    puts "Sample variance without replacement: #{monte_wor.to_vector(:scale).variance_population}"
    puts "Mean sd estimadet :#{vsd*Math::sqrt(ss-1)}"
    puts "Mean Sd W/R: #{s_wr}" 
    puts "Mean Sd WO/R: #{s_wor}" 

	mx=mw.mean
    er=mw.sds

	prev=0
	mw.frequencies.sort.each{|x,y|
        t=(x-vm).quo(s_wr.quo(Math::sqrt(ss))*s_wr.quo(ss-1))
        z=(x-vm).quo(vsd.quo(Math::sqrt(ss)))
		xxz.push(z)
        xxt.push(t)
		prev+=y
		xy.push(prev.to_f/tests)
		xt.push(GSL::Cdf.tdist_P(t, ss-1))
		xz.push(GSL::Cdf.gaussian_P(z))

	}
	plot.data << Gnuplot::DataSet.new( [xxt,xy] ) do |ds|
		ds.with="lines"
		ds.title = "sim #{sample_size}"
	end
	plot.data << Gnuplot::DataSet.new( [xxt,xt] ) do |ds|
		ds.with="lines"
		ds.title = "t #{sample_size}"
	end
	plot.data << Gnuplot::DataSet.new( [xxz,xz] ) do |ds|
		ds.with="lines"
		ds.title = "z"
	end
	
}

end
end
	
