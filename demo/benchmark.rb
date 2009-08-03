require File.dirname(__FILE__)+'/../lib/statsample.rb'
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

 n = 300
 if (false)
     Benchmark.bm(7) do |bench|
         bench.report("missing or")   { for i in 1..n; v.each {|x|             !(x.nil? or v.missing_values.include? x) }; end }
         bench.report("missing and")   { for i in 1..n;v.each {|x|             !x.nil? and !v.missing_values.include? x } ; end }
    end
 end
 if (false)
     Benchmark.bm(7) do |bench|
         bench.report("true")   { Statsample::OPTIMIZED=true; for i in 1..n; v.set_valid_data ; end }
         bench.report("false")   { Statsample::OPTIMIZED=false; for i in 1..n; v.set_valid_data ; end }
    end
 end


 if (true)
    Benchmark.bm(7) do |x|
		x.report("mean")   { for i in 1..n; v.mean; end }
		x.report("slow_mean")   { for i in 1..n; v.mean_slow; end }

    end

    Benchmark.bm(7) do |x|
		x.report("variance_sample")   { for i in 1..n; v.variance_sample; end }
		x.report("variance_slow")   { for i in 1..n; v.slow_variance_sample; end }

    end


    Benchmark.bm(7) do |x|
		
		x.report("Nominal.frequencies")   { for i in 1..n; v.frequencies; end }
		x.report("Nominal.frequencies_slow")   { for i in 1..n; v.frequencies_slow; end }

		x.report("_frequencies")   { for i in 1..n; Statsample._frequencies(v.valid_data); end }

    end

end
