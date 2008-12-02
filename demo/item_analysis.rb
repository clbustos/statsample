#!/usr/bin/ruby
require File.dirname(__FILE__)+'/../lib/rubyss'
ds=RubySS::CSV.read(File.dirname(__FILE__)+"/sample_test.csv")
ds2={}
(24..61).each {|v|
    ds2["p"+v.to_s]=ds['p'+v.to_s].recode{|c|
        c.to_f
    }
    ds2["p"+v.to_s].type=:scale
}

a= RubySS::Reliability::ItemAnalysis.new(ds2.to_dataset)
File.open("test.html","w") {|fp|
    fp.puts a.html_summary
}

a.svggraph_correct_responses_distribution(File.dirname(__FILE__)+"/images","internet")
    
