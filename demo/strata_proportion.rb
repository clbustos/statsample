require File.dirname(__FILE__)+"/../lib/rubyss"
require 'rubyss/multiset'
require 'rubyss/srs'
require 'rubyss/resample'
require 'gnuplot'

tests=3000
sample_size=100

a=[1]*50+[0]*950
b=[1]*900+[0]*100
a_size=a.size
b_size=b.size
av=a.to_vector(:scale)
bv=b.to_vector(:scale)

ads={'data'=>a.to_vector(:scale)}.to_dataset
bds={'data'=>b.to_vector(:scale)}.to_dataset

m=RubySS::Multiset.new(['data'])
m.add_dataset('a',ads)
m.add_dataset('b',bds)
ss=RubySS::StratifiedSample.new(m,{'a'=>a.size,'b'=>b.size})

es=[{'N'=>a_size,'n'=>sample_size/2,'s'=>av.standard_deviation_population}, {'N'=>b_size,'n'=>sample_size/2,'s'=>bv.standard_deviation_population}]

esp=[{'N'=>a_size,'n'=>sample_size/2,'p'=>av.proportion(1.0)}, {'N'=>b_size,'n'=>sample_size/2,'p'=>bv.proportion(1.0)}]



sd_estimated_wr=RubySS::StratifiedSample.standard_error_ksd_wr(es)

sd_estimated_wor = RubySS::StratifiedSample.standard_error_ksd_wor(es)

sd_estimated_wor_p = RubySS::StratifiedSample.proportion_sd_ksd_wor(esp)
sd_estimated_wr_p = RubySS::StratifiedSample.proportion_sd_ksd_wr(esp)

pop=(a+b).to_vector(:scale)
s=pop.standard_deviation_population




puts "-------------"

puts "Estadísticos:"
puts "Mean:"+pop.mean.to_s
puts "SD:"+s.to_s
puts "EE con reemplazo:"+RubySS::SRS.standard_error_ksd_wr(s, sample_size, pop.size).to_s
puts "EE sin reemplazo:"+RubySS::SRS.standard_error_ksd_wor(s, sample_size,pop.size).to_s



puts "EE estratified con reemplazo:"+sd_estimated_wr.to_s
puts "EE estratified sin reemplazo:"+sd_estimated_wor.to_s
puts "EE estratified con reemplazo(p):"+sd_estimated_wr_p.to_s
puts "EE estratified sin reemplazo(p):"+sd_estimated_wor_p.to_s

sd_with=[]
sd_without=[]
sd_strat_wr=[]
sd_strat_wor_1=[]
sd_strat_wor_2=[]
monte_with=RubySS::Resample.repeat_and_save(tests) {
    sample= pop.sample_with_replacement(sample_size)
    sd_with.push(RubySS::SRS.standard_error_esd_wr(sample.sds,sample_size,pop.size))
    sample.mean
}


monte_without=RubySS::Resample.repeat_and_save(tests) {
    sample= pop.sample_without_replacement(sample_size)
    sd_without.push(RubySS::SRS.standard_error_esd_wor(sample.sds,sample_size,pop.size))
    sample.mean
}



stratum_wor=RubySS::Resample.repeat_and_save(tests) {
    a_sample= {'data'=>av.sample_without_replacement(sample_size/2)}.to_dataset
    b_sample= {'data'=>bv.sample_without_replacement(sample_size/2)}.to_dataset
    m=RubySS::Multiset.new(['data'])
    m.add_dataset('a',a_sample)
    m.add_dataset('b',b_sample)
    ss=RubySS::StratifiedSample.new(m,{'a'=>a_size,'b'=>b_size})
    sd_strat_wor_1.push(ss.standard_error_wor('data'))
    sd_strat_wor_2.push(ss.proportion_sd_esd_wor('data',1.0))
    ss.mean('data')    
}.to_vector(:scale)

stratum_wr=RubySS::Resample.repeat_and_save(tests) {
    a_sample= {'data'=>av.sample_with_replacement(sample_size/2)}.to_dataset
    b_sample= {'data'=>bv.sample_with_replacement(sample_size/2)}.to_dataset
    m=RubySS::Multiset.new(['data'])
    m.add_dataset('a',a_sample)
    m.add_dataset('b',b_sample)
    ss=RubySS::StratifiedSample.new(m,{'a'=>a_size,'b'=>b_size})
    sd_strat_wr.push(ss.standard_error_wr('data'))
    ss.mean('data')    
}.to_vector(:scale)



v_sd_with=sd_with.to_vector(:scale)
v_sd_without=sd_without.to_vector(:scale)
v_sd_strat_wr=sd_strat_wr.to_vector(:scale)
v_sd_strat_wor_1=sd_strat_wor_1.to_vector(:scale)
v_sd_strat_wor_2=sd_strat_wor_2.to_vector(:scale)

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
puts "Sd (estimated scale):"+v_sd_strat_wor_1.mean.to_s
puts "Sd (estimated prop):"+v_sd_strat_wor_2.mean.to_s

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
