require File.dirname(__FILE__)+"/../lib/rubyss"
require 'rubyss/srs'
require 'rubyss/resample'
require 'gnuplot'

tests=3000
# rand a 50%
monte_with=RubySS::Resample.repeat_and_save(tests) {
    (1+rand(6))+(1+rand(6))
}.to_vector(:scale)

p monte_with.mean

