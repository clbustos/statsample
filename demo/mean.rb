basedir=File.dirname(__FILE__)
require basedir+"/../lib/rubyss"
require 'rubyss/srs'
require 'rubyss/multiset'
require 'gnuplot'
require 'rubyss/graph/svggraph.rb'
tests=10000
sample_size=100

a=[]
(-20..+20).to_a.each {|i|
    z=i/10.0
    a+=[GSL::Ran.ugaussian_pdf(z)*1000]*25
}



pop=a.to_vector(:scale)

pop.svggraph_histogram(10,basedir+"/images/mean_pop.svg")

s=pop.standard_deviation_population
puts "Parameters:"
puts "Mean:"+pop.mean.to_s
puts "SD:"+s.to_s
puts "SE with replacement:"+RubySS::SRS.standard_error_ksd_wr(s, sample_size, pop.size).to_s
puts "SE without replacement:"+RubySS::SRS.standard_error_ksd_wor(s, sample_size,pop.size).to_s

sd_with=[]
sd_without=[]
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


v_sd_with=sd_with.to_vector(:scale)
v_sd_without=sd_without.to_vector(:scale)

v_with=monte_with.to_vector(:scale)
v_without=monte_without.to_vector(:scale)
puts "=============="
puts "Sample distribution - with Replacement"
puts "Mean:"+v_with.mean.to_s
puts "Sd:"+v_with.sds.to_s
puts "Sd (estimated):"+v_sd_with.mean.to_s
puts "Sample distribution - without Replacement"
puts "Mean:"+v_without.mean.to_s
puts "Sd:"+v_without.sds.to_s
puts "Sd (estimated):"+v_sd_without.mean.to_s

v_without.svggraph_histogram(10,basedir+"/images/mean_wo_hist.svg")
