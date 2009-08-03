require File.dirname(__FILE__)+"/../lib/statsample"
require 'statsample/srs'
require 'statsample/resample'
require 'gnuplot'

tests=3000
sample_size=100
# rand a 50%
poblacion=([1]*500+[0]*500).to_vector(:scale)
prop=poblacion.proportion(1)
puts "Estadísticos"
puts "DE con reemplazo:"+Statsample::SRS.proportion_sd_kp_wr(prop, sample_size).to_s
puts "DE sin reemplazo:"+Statsample::SRS.proportion_sd_kp_wor(prop, sample_size,poblacion.size).to_s

sd_with=[]
sd_without=[]
monte_with=Statsample::Resample.repeat_and_save(tests) {
    pob= poblacion.sample_with_replacement(sample_size)
    sd_with.push(Statsample::SRS.proportion_sd_ep_wr(pob.mean,sample_size))
    pob.mean
}


monte_without=Statsample::Resample.repeat_and_save(tests) {
    pob= poblacion.sample_without_replacement(sample_size)
    sd_without.push(Statsample::SRS.proportion_sd_ep_wor(pob.mean,sample_size,poblacion.size))
    pob.mean
}


v_sd_with=sd_with.to_vector(:scale)
v_sd_without=sd_without.to_vector(:scale)

v_with=monte_with.to_vector(:scale)
v_without=monte_without.to_vector(:scale)
puts "With replacement"
puts "Mean:"+v_with.mean.to_s
puts "Sd:"+v_with.sds.to_s
puts "Sd (estimated):"+v_sd_with.mean.to_s
puts "Without replacement"
puts "Mean:"+v_without.mean.to_s
puts "Sd:"+v_without.sds.to_s
puts "Sd (estimated):"+v_sd_without.mean.to_s
=begin

x=[]
y=[]
y2=[]
prev=0
prev_chi=0
v.frequencies.sort.each{|k,v1|
	x.push(k)
	y.push(prev+v1)
	prev=prev+v1
}
GSL::graph(GSL::Vector.alloc(x),  GSL::Vector.alloc(y))
=end
