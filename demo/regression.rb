require File.dirname(__FILE__)+'/../lib/statsample'
tests=300
include Statsample
r = GSL::Rng.alloc(GSL::Rng::TAUS,Time.now.to_i)
ds=Dataset.new(%w{a b c d y})
    ds['a'].type=:scale
    ds['b'].type=:scale
    ds['c'].type=:scale
    ds['d'].type=:scale
    ds['y'].type=:scale
    
    tests.times {
    a=r.ugaussian
    b=r.ugaussian
    c=r.ugaussian
    d=r.ugaussian
    y=a*70+b*30+c*5+r.ugaussian*5
    ds.add_case_array([a,b,c,d,y])
}
ds.update_valid_data

if !File.exists? "regression.dab"
    da=DominanceAnalysis::Bootstrap.new(ds,"y")
else
    da=Statsample.load("regression.dab")
end
    
da.lr_class=Regression::Multiple::AlglibEngine
da.bootstrap(20)

puts da.summary
da.save("regression.dab")

lr=Regression::Multiple.listwise(ds,"y")

hr=HtmlReport.new("Regression")
hr.add_summary("Regression",lr.summary(HtmlSummary))
hr.add_summary("Analisis de Dominancia ", da.da.summary(HtmlSummary))

hr.add_summary("Analisis de Dominancia (Bootstrap)", da.summary(HtmlSummary))

da.fields.each{|f|
 hr.add_histogram("General Dominance #{f}",da.samples_ga[f].to_vector(:scale))
}
hr.save("Regression Dominance.html")

