#!/usr/bin/ruby
require File.dirname(__FILE__)+'/../lib/rubyss'
ds=RubySS::CSV.read(File.dirname(__FILE__)+"/sample_test.csv")

fp=File.new(File.dirname(__FILE__)+"/item_analysis/Analisis.html","w")

[['general', (1..23)], ['word',(24..61)], ['excel',(62..82)], ['pp',(83..92)],['internet',(93..101)]].each{|dim,range|
ds2={}

    fp.puts("<h1>Dimension: #{dim}</h1>")
    
    range.each {|v|

    ds2["p"+v.to_s]=ds['p'+v.to_s].recode{|c|
        c.nil? ? nil : c.to_f
    }
    ds2["p"+v.to_s].type=:scale
}

a= RubySS::Reliability::ItemAnalysis.new(ds2.to_dataset)

fp.puts(a.html_summary)
a.svggraph_item_characteristic_curve(File.dirname(__FILE__) + "/item_analysis",dim)
range.each{|v|
    fp.puts("<p><img src='#{dim}_p#{v}.svg' /></p>\n")
}
}

fp.close

