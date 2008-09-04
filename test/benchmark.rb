require File.dirname(__FILE__)+'/../lib/rubyss.rb'
require 'benchmark'
v=(0..10000).collect{|n|
	r=rand(100)
    if(r<90)
    r 
    else
        nil
    end
}.to_vector
v.missing_values=[5,10,20]
v.type=:scale

 n = 1000
 if (false)
    Benchmark.bm(7) do |x|
		x.report("mean")   { for i in 1..n; v.mean; end }
		x.report("slow_mean")   { for i in 1..n; v.slow_mean; end }

    end

    Benchmark.bm(7) do |x|
		x.report("variance_sample")   { for i in 1..n; v.variance_sample; end }
		x.report("variance_slow")   { for i in 1..n; v.slow_variance_sample; end }

    end


    Benchmark.bm(7) do |x|
		
		x.report("Nominal.frequencies")   { for i in 1..n; v.frequencies; end }
		x.report("Nominal.frequencies_slow")   { for i in 1..n; v.frequencies_slow; end }

		x.report("_frequencies")   { for i in 1..n; RubySS._frequencies(v.valid_data); end }

    end

end

    Benchmark.bm(10) do |x|
		x.report("is_valid_and")   { for i in 1..n; v.is_valid?(10);v.is_valid?(20); v.is_valid?(30); end }
		x.report("is_valid_or")   { for i in 1..n; v.is_valid2?(10);v.is_valid2?(20); v.is_valid2?(30); end }
    end

