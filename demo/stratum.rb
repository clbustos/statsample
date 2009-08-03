require File.dirname(__FILE__)+"/../lib/statsample"
require 'statsample/multiset'
require 'statsample/srs'
require 'statsample/resample'
require 'gnuplot'

tests=3000
sample_size=50

a=[10]*50+[12]*10+[14]*20+[16]*10+[19]*10
b=[11000]*50+[11050]*10+[11100]*20+[11300]*10+[11240]*10
a_size=a.size
b_size=b.size
av=a.to_vector(:scale)
bv=b.to_vector(:scale)

ads={'data'=>a.to_vector(:scale)}.to_dataset
bds={'data'=>b.to_vector(:scale)}.to_dataset

m=Statsample::Multiset.new(['data'])
m.add_dataset('a',ads)
m.add_dataset('b',bds)
ss=Statsample::StratifiedSample.new(m,{'a'=>a.size,'b'=>b.size})

es=[{'N'=>a_size,'n'=>sample_size/2,'s'=>av.standard_deviation_population}, {'N'=>b_size,'n'=>sample_size/2,'s'=>bv.standard_deviation_population}]



sd_estimated_wr=Statsample::StratifiedSample.standard_error_ksd_wr(es)

sd_estimated_wor = Statsample::StratifiedSample.standard_error_ksd_wor(es)



pop=(a+b).to_vector(:scale)
s=pop.standard_deviation_population




puts "-------------"

puts "Estadísticos:"
puts "Mean:"+pop.mean.to_s
puts "SD:"+s.to_s
puts "EE con reemplazo:"+Statsample::SRS.standard_error_ksd_wr(s, sample_size, pop.size).to_s
puts "EE sin reemplazo:"+Statsample::SRS.standard_error_ksd_wor(s, sample_size,pop.size).to_s

puts "EE estratified con reemplazo:"+sd_estimated_wr.to_s
puts "EE estratified sin reemplazo:"+sd_estimated_wor.to_s
sd_with=[]
sd_without=[]
sd_strat_wr=[]
sd_strat_wor=[]
monte_with=Statsample::Resample.repeat_and_save(tests) {
    sample= pop.sample_with_replacement(sample_size)
    sd_with.push(Statsample::SRS.standard_error_esd_wr(sample.sds,sample_size,pop.size))
    sample.mean
}


monte_without=Statsample::Resample.repeat_and_save(tests) {
    sample= pop.sample_without_replacement(sample_size)
    sd_without.push(Statsample::SRS.standard_error_esd_wor(sample.sds,sample_size,pop.size))
    sample.mean
}



stratum_wor=Statsample::Resample.repeat_and_save(tests) {
    a_sample= {'data'=>av.sample_without_replacement(sample_size/2)}.to_dataset
    b_sample= {'data'=>bv.sample_without_replacement(sample_size/2)}.to_dataset
    m=Statsample::Multiset.new(['data'])
    m.add_dataset('a',a_sample)
    m.add_dataset('b',b_sample)
    ss=Statsample::StratifiedSample.new(m,{'a'=>a_size,'b'=>b_size})
    sd_strat_wor.push(ss.standard_error_wor('data'))
    ss.mean('data')    
}.to_vector(:scale)

stratum_wr=Statsample::Resample.repeat_and_save(tests) {
    a_sample= {'data'=>av.sample_with_replacement(sample_size/2)}.to_dataset
    b_sample= {'data'=>bv.sample_with_replacement(sample_size/2)}.to_dataset
    m=Statsample::Multiset.new(['data'])
    m.add_dataset('a',a_sample)
    m.add_dataset('b',b_sample)
    ss=Statsample::StratifiedSample.new(m,{'a'=>a_size,'b'=>b_size})
    sd_strat_wr.push(ss.standard_error_wr('data'))
    ss.mean('data')    
}.to_vector(:scale)



v_sd_with=sd_with.to_vector(:scale)
v_sd_without=sd_without.to_vector(:scale)
v_sd_strat_wr=sd_strat_wr.to_vector(:scale)
v_sd_strat_wor=sd_strat_wor.to_vector(:scale)


v_with=monte_with.to_vector(:scale)
v_without=monte_without.to_vector(:scale)
puts "=============="
puts "Con reemplazo"
puts "Mean:"+v_with.mean.to_s
puts "Sd:"+v_with.sds.to_s
puts "Sd (estimated):"+v_sd_with.mean.to_s
puts "=============="
puts "Sin reemplazo"
puts "Mean:"+v_without.mean.to_s
puts "Sd:"+v_without.sds.to_s
puts "Sd (estimated):"+v_sd_without.mean.to_s
puts "=============="
puts "Estratificado Con reemplazo"
puts "Mean:"+stratum_wr.mean.to_s
puts "Sd:"+stratum_wr.sds.to_s
puts "Sd (estimated):"+v_sd_strat_wr.mean.to_s

puts "=============="
puts "Estratificado Sin reemplazo"
puts "Mean:"+stratum_wor.mean.to_s
puts "Sd:"+stratum_wor.sds.to_s
puts "Sd (estimated):"+v_sd_strat_wor.mean.to_s

p v_without.plot_histogram

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
