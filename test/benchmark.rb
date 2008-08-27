require File.dirname(__FILE__)+'/../lib/rubyss.rb'
require 'benchmark'
v=(0..10000).collect{|n|
	rand(10000)
}.to_vector
v.type=:scale
p v.slow_variance_sample
p v.variance_sample

 n = 50
    Benchmark.bm(7) do |x|
		x.report("mean")   { for i in 1..n; v.mean; end }
		x.report("slow_mean")   { for i in 1..n; v.slow_mean; end }

    end

    Benchmark.bm(7) do |x|
		x.report("variance_sample")   { for i in 1..n; v.variance_sample; end }
		x.report("variance_slow")   { for i in 1..n; v.slow_variance_sample; end }

    end

