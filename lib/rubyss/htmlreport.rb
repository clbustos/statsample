module RubySS
    class HtmlReport
    def initialize(ds,name,dir=nil)
        require 'fileutils'
        @ds=ds
        @name=name
        @partials=[]
        dir||=@name+"/"
        @dir=dir
        FileUtils.mkdir(@dir) if !File.exists? @dir
    end
    # Add a scale
    # First arg is the name of the scale
    # Other are fields
    def add_scale(name, fields)
        raise "Fields are empty" if fields.size==0
        ds_partial=@ds.dup(fields)
        ia=RubySS::Reliability::ItemAnalysis.new(ds_partial)
        html="<h2>Scale: #{name}</h2>"
        html << ia.html_summary
        hist_file=@dir+"/#{name}.svg"
        ds_partial.vector_sum.svggraph_histogram(5,hist_file,500,400)
        html << "<h3>Histogram</h3> <p><embed src='#{hist_file}'  width='500' height='400' type='image/svg+xml' /></p>\n"
        html << "<h3>ICC</h3>"
        
        ia.svggraph_item_characteristic_curve(@dir ,name, {:width=>400,:height=>300})
        ds_partial.fields.sort.each{|f|
            html << "<div><p><strong>#{f}</strong></p><embed src='#{@dir}/#{name}_#{f}.svg'  width='400' height='300' type='image/svg+xml' /></div>\n"
        }
        @partials.push(html)
    end
    def parse
        html="<html><head><title>#{@name}</title></head><body><h1>Report: #{@name}</h1>"
        html+="<div class='section'>"+@partials.join("</div><div class='section'>")+"</div>"
        html+="</body></html>"
        html
    end
    def save(filename)
        File.open(filename,"w") {|fp|
            fp.write(parse)
        }
    end
end
end
