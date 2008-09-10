require File.dirname(__FILE__)+"/../lib/rubyss"
require 'rubyss/multiset'
require 'rubyss/resample'
require 'gnuplot'

tests=1000
sample_size=50

a=[10]*50+[12]*10+[14]*20+[16]*10+[19]*10
b=[1000]*50+[1050]*10+[1100]*20+[1300]*10+[1240]*10
a_size=a.size
b_size=b.size


ads={'data'=>a.to_vector(:scale)}.to_dataset
bds={'data'=>b.to_vector(:scale)}.to_dataset

m=RubySS::Multiset.new(['data'])
m.add_dataset('a',ads)
m.add_dataset('b',bds)
ss=RubySS::StratifiedSample.new(m,{'a'=>a.size,'b'=>b.size})

sd_estimated=ss.standard_error('data')



pop=(a+b).to_vector(:scale)
s=pop.standard_deviation_population




puts "-------------"

puts "Estadísticos:"
puts "Mean:"+pop.mean.to_s
puts "SD:"+s.to_s
puts "EE con reemplazo:"+RubySS::standard_error_ksd_wr(s, sample_size, pop.size).to_s
puts "EE sin reemplazo:"+RubySS::standard_error_ksd_wor(s, sample_size,pop.size).to_s

puts "EE estratified:"+sd_estimated.to_s

sd_with=[]
sd_without=[]
sd_strat=[]
monte_with=RubySS::Resample.repeat_and_save(tests) {
    sample= pop.sample_with_replacement(sample_size)
    sd_with.push(RubySS::standard_error_esd_wr(sample.sds,sample_size,pop.size))
    sample.mean
}


monte_without=RubySS::Resample.repeat_and_save(tests) {
    sample= pop.sample_without_replacement(sample_size)
    sd_without.push(RubySS::standard_error_esd_wor(sample.sds,sample_size,pop.size))
    sample.mean
}

av=a.to_vector(:scale)
bv=b.to_vector(:scale)

stratum=RubySS::Resample.repeat_and_save(tests) {
    a_sample= {'data'=>av.sample_without_replacement(sample_size/2)}.to_dataset
    b_sample= {'data'=>bv.sample_without_replacement(sample_size/2)}.to_dataset
    m=RubySS::Multiset.new(['data'])
    m.add_dataset('a',a_sample)
    m.add_dataset('b',b_sample)
    ss=RubySS::StratifiedSample.new(m,{'a'=>a_size,'b'=>b_size})
    sd_strat.push(ss.standard_error('data'))
    ss.mean('data')    
}.to_vector(:scale)



v_sd_with=sd_with.to_vector(:scale)
v_sd_without=sd_without.to_vector(:scale)
v_sd_strat=sd_strat.to_vector(:scale)

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
puts "Estratificado"
puts "Mean:"+stratum.mean.to_s
puts "Sd:"+stratum.sds.to_s
puts "Sd (estimated):"+v_sd_strat.mean.to_s

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
