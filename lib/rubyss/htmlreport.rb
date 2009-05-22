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
    def add_correlation_matrix()
        html="<h2>Correlation Matrix</h2> <table><thead><th>-</th><th>"+@ds.fields.join("</th><th>")+"</th> </thead> <tbody>"
        matrix=RubySS::Correlation.correlation_matrix(@ds)
        pmatrix=RubySS::Correlation.correlation_probability_matrix(@ds)

      
        (0...(matrix.row_size)).each {|row|
            html+="<tr><td>"+@ds.fields[row]+"</td>"
            (0...(matrix.column_size)).each {|col|
                if matrix[row,col].nil?
                    html+="<td>--</td>"
                else
                    sig=""
                    prob_out=""
                    if !pmatrix[row,col].nil?
                        prob=pmatrix[row,col]
                        prob_out=sprintf("%0.3f",prob)
                        if prob<0.01
                            sig="**"
                        elsif prob<0.05
                            sig="*"
                        else
                            sig=""
                        end
                    end
                    if sig==""
                        html+="<td>#{sprintf("%0.3f",matrix[row,col])} #{sig}<br /> #{prob_out}</td>"
                    else
                        html+="<td><strong>#{sprintf("%0.3f",matrix[row,col])} #{sig}<br /> #{prob_out}</strong></td>"

                    end
                end
            }
            html+="</tr>"
        }
        html+="</tbody></table>"
        @partials.push(html)
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
    def css
<<HERE
table {
border-collapse:collapse;
}
table td {
border: 1px solid black;
}
HERE
    end
    def parse
        html="<html><head><title>#{@name}</title><style>#{css()}</style></head><body><h1>Report: #{@name}</h1>"
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
