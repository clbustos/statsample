require File.dirname(__FILE__)+'/../lib/statsample'
require 'benchmark'
tests=300
include Statsample
ds=Dataset.new(%w{a b c d y})
    ds['a'].type=:scale
    ds['b'].type=:scale
    ds['c'].type=:scale
    ds['d'].type=:scale
    ds['y'].type=:scale

if HAS_GSL
r = GSL::Rng.alloc(GSL::Rng::TAUS,Time.now.to_i)
    
    tests.times {
    a=r.ugaussian
    b=a*2+r.ugaussian
    c=r.ugaussian
    d=r.ugaussian
    y=a*70+b*30+c*5+r.ugaussian*5
    ds.add_case_array([a,b,c,d,y])
}
else
    tests.times {
        a=1-rand()*2.0
    b=1-rand()*2.0
    c=1-rand()*2.0
    d=1-rand()*2.0
    y=a*70+b*30+c*5+(1-rand()*2.0)*5
    ds.add_case_array([a,b,c,d,y])
}
    
    
end
ds.update_valid_data

if !File.exists? "regression.dab"
    da=DominanceAnalysis::Bootstrap.new(ds,"y")
else
    da=Statsample.load("regression.dab")
end
times=1
if(true)
Benchmark.bm(7) do |x|
    if HAS_GSL
    x.report("GslEngine:") {
        da.lr_class=Regression::Multiple::GslEngine
        da.bootstrap(times)
    }
    end
    if(false)
    if HAS_ALGIB
    x.report("AlglibEngine:") {
        da.lr_class=Regression::Multiple::AlglibEngine
        da.bootstrap(times)
    }
    end
    x.report("RubyEngine:") {
        da.lr_class=Regression::Multiple::RubyEngine
        da.bootstrap(times)
    }
    end
end
end

puts da.summary
da.save("regression.dab")

lr=Regression::Multiple.listwise(ds,"y")

hr=HtmlReport.new("Regression")
hr.add_summary("Regression",lr.summary(HtmlSummary))
hr.add_summary("Analisis de Dominancia ", da.da.summary(HtmlSummary))
hr.add_correlation_matrix(ds)
hr.add_summary("Analisis de Dominancia (Bootstrap)", da.summary(HtmlSummary))

da.fields.each{|f|
# hr.add_histogram("General Dominance #{f}",da.samples_ga[f].to_vector(:scale))
}
hr.save("Regression Dominance.html")

