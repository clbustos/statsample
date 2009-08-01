require File.dirname(__FILE__)+"/../lib/rubyss"


tests=3000

r = GSL::Rng.alloc(GSL::Rng::TAUS, 1)
sample_sizes=[5,10,20,30]
sample_sizes.each{|sample_size|
monte=RubySS::Resample.repeat_and_save(tests) {
    v=[]
    sample_size.times{|i|
        v.push(r.ugaussian)
    }
    v.to_vector(:scale).mean

}
}
