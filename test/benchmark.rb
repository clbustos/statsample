require File.dirname(__FILE__)+'/../lib/rubyss.rb'
require 'benchmark'
v=(0..10000).collect{|n|
	rand(100)
}.to_vector
v.type=:scale

 n = 200
 if (false)
    Benchmark.bm(7) do |x|
		x.report("mean")   { for i in 1..n; v.mean; end }
		x.report("slow_mean")   { for i in 1..n; v.slow_mean; end }

    end

    Benchmark.bm(7) do |x|
		x.report("variance_sample")   { for i in 1..n; v.variance_sample; end }
		x.report("variance_slow")   { for i in 1..n; v.slow_variance_sample; end }

    end
end

    Benchmark.bm(7) do |x|
		
		x.report("Nominal.frequencies")   { for i in 1..n; v.frequencies; end }
		x.report("Nominal.frequencies_slow")   { for i in 1..n; v.frequencies_slow; end }

		x.report("_frequencies")   { for i in 1..n; RubySS._frequencies(v.valid_data); end }

    end


