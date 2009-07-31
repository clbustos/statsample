require 'rubyss/graph/svggraph'

module RubySS
    class HtmlReport
    def initialize(name,dir=nil)
        require 'fileutils'
        @uniq=1
        @uniq_file=0
        @name=name
        @partials=[]
        @anchors=[]
        dir||=@name+"/"
        @dir=dir
        @level=1
        FileUtils.mkdir(@dir) if !File.exists? @dir
    end
    def add_summary(name,summary)
        add_anchor(name)
        @partials.push(summary)
    end
    def add_anchor(name)
        @anchors.push([name,@level,@uniq])
        @partials.push("<a name='#{@uniq}'> </a>")
        @uniq+=1
    end
    def uniq_file(prepend="file")
        @uniq_file+=1
        "#{prepend}_#{@uniq_file}_#{Time.now.to_i}"
    end
    def add_correlation_matrix(ds)
        add_anchor("Correlation Matrix")
        html="<h2>Correlation Matrix</h2> <table><thead><th>-</th><th>"+ds.fields.join("</th><th>")+"</th> </thead> <tbody>"
        matrix=RubySS::Bivariate.correlation_matrix(ds)
        pmatrix=RubySS::Bivariate.correlation_probability_matrix(ds)

      
        (0...(matrix.row_size)).each {|row|
            html+="<tr><td>"+ds.fields[row]+"</td>"
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
    def add_scale(ds,name, fields,icc=false)
        raise "Fields are empty" if fields.size==0
        add_anchor("Scale:#{name}")
        
        ds_partial=ds.dup(fields)
        ia=RubySS::Reliability::ItemAnalysis.new(ds_partial)
        html="<h2>Scale: #{name}</h2>"
        html << ia.html_summary
        @partials.push(html)
        @level+=1
        v=ds_partial.vector_mean
            add_histogram(name, v)        
            add_runsequence_plot(name, v)        
            add_normalprobability_plot(name,v)
            add_icc(name,fields) if icc
        @level-=1
    end
    
    def add_boxplot(name,vector,options={})
        add_graph("Box Plot #{name}", name, vector.svggraph_boxplot(options))
    end    
    def add_graph(name,id,graph)
        add_anchor(name)
        rs_file=@dir+"/#{uniq_file()}.svg"
        html = "<h3>#{name}</h3> <p><embed src='#{rs_file}'  width='#{graph.width}' height='#{graph.height}' type='image/svg+xml' /></p>\n"
        File.open(rs_file, "w") {|f|
            f.puts(graph.burn)
        }
        @partials.push(html)
    end
    def add_runsequence_plot(name, vector,options={})
        add_graph("Run-Sequence Plot #{name}", name, vector.svggraph_runsequence_plot(options))
    end
    def add_lag_plot(name,vector, options={})
        add_graph("Lag Plot #{name}", name,vector.svggraph_lag_plot(options))
    end
        
    def add_normalprobability_plot(name,vector,options={})
        add_graph("Normal Probability Plot #{name}", name, vector.svggraph_normalprobability_plot(options))
    end

    def add_scatterplot(name, ds,x_field=nil, y_fields=nil,config={})
        add_anchor("Scatterplot: #{name}")
        x_field||=ds.fields[0]
        y_fields||=ds.fields-[x_field]
        ds_partial=ds.dup([x_field]+y_fields)
        sc=RubySS::Graph::SvgScatterplot.new(ds_partial, config)
        sc.parse
        sc_file=@dir+"/#{uniq_file("sc")}.svg"
        html = "<h3>Scatterplot #{name}</h3> <p><embed src='#{sc_file}'  width='#{sc.width}' height='#{sc.height}' type='image/svg+xml' /></p>\n"
        File.open(sc_file, "w") {|f|
              f.puts(sc.burn)
        }
        @partials.push(html)
    end
    
    
    def add_boxplots(name, ds,options={})
        add_anchor("Boxplots: #{name}")
        options={:graph_title=>"Boxplots:#{name}", :show_graph_title=>true, :height=>500}.merge! options
        graph = RubySS::Graph::SvgBoxplot.new(options)
        ds.fields.each{|f|
            graph.add_data(:title=>f, 
                :data=>ds[f].valid_data,
                :vector=>ds[f]
                )
        }
        add_graph(name,name,graph)
        graph
    end
    def add_histogram(name,vector,bins=nil,options={})
        bins||=vector.size / 15
        bins=15 if bins>15 
        graph=vector.svggraph_histogram(bins,options)
        add_graph("Histogram:#{name}",name,graph)
        html = "<ul><li>Skewness=#{sprintf("%0.3f",vector.skew)}</li>
        <li>Kurtosis=#{sprintf("%0.3f",vector.kurtosis)}</li></ul>"
        @partials.push(html)
    end
    def add_icc(name,ds, fields)
        require 'rubyss/graph/svggraph'
        raise "Fields are empty" if fields.size==0
        add_anchor("ICC:#{name}")        
        ds_partial=ds.dup(fields)
        ia=RubySS::Reliability::ItemAnalysis.new(ds_partial)
        html="<h3>ICC for scale: #{name}</h3>"
        ia.svggraph_item_characteristic_curve(@dir ,name, {:width=>400,:height=>300})
        ds_partial.fields.sort.each{|f|
            html << "<div><p><strong>#{f}</strong></p><embed src='#{@dir}/#{name}_#{f}.svg'  width='400' height='300' type='image/svg+xml' /></div>\n"
        }
        @partials.push(html)
    end
    def css
<<HERE
table {
  border-collapse: collapse;
}
th {
  text-align: left;
  padding-right: 1em;
  border-bottom: 3px solid #ccc;
}
th.active img {
  display: inline;
}
tr.even, tr.odd {
  background-color: #eee;
  border-bottom: 1px solid #ccc;
}
tr.even, tr.odd {
  padding: 0.1em 0.6em;
}
td.active {
  background-color: #ddd;
}
table td {
border:1px solid #aaa;
}
table tr.line td{
border-top: 2px solid black;
}

HERE
    end
    
    def create_uls(level)
        if @c_level!=level
            if level>@c_level
                "<ul>\n" * (level-@c_level)
            else
                "</ul>\n" * (@c_level-level)
            end
        else
            ""
        end
    end
    
    def parse
        html="<html><head><title>#{@name}</title><style>#{css()}</style></head><body><h1>Report: #{@name}</h1>"
        if @anchors.size>0
            html << "<div class='index'>Index</div><ul>"
            @c_level=1
            @anchors.each{|name,level,uniq|
                html << create_uls(level)
                @c_level=level
                html << "<li><a href='#"+uniq.to_s+"'>#{name}</a></li>"
            }
            html << create_uls(1)
            html << "</ul></div>"
        end
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
