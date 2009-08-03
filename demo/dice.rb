require File.dirname(__FILE__)+"/../lib/statsample"
require 'statsample/srs'
require 'statsample/resample'
require 'gnuplot'

tests=3000
# rand a 50%
monte_with=Statsample::Resample.repeat_and_save(tests) {
    (1+rand(6))+(1+rand(6))
}.to_vector(:scale)

p monte_with.mean

