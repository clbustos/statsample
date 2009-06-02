module RubySS
    module Graph
class SvgHistogram < SVG::Graph::BarBase
    attr_accessor :inner_margin, :mean, :sigma, :show_normal
        def initialize(config)
            config[:fields]=[:dummy]
            super
            
            @histogram=nil
        end
		include REXML
		
			# In addition to the defaults set in Graph::initialize, sets
			# [inner_margin] 14
			# [key] false
		def set_defaults 
		 super
		 self.top_align = self.top_font = 0
         init_with({
            :inner_margin=>16,
            :key=>false,
            :show_normal=>false
            })
         
		end
		
        def histogram=(h)
            @histogram=h
            @data=[{:data=>(0...@histogram.bins).to_a.collect {|i|
                @histogram[i]
            }}]
        end
		def get_x_labels
            [""]
		end
        
		def get_y_labels
            maxvalue = max_value
            minvalue = min_value
            range = maxvalue - minvalue
            
            top_pad = range == 0 ? 10 : range / 20.0
            scale_range = (maxvalue + top_pad) - minvalue
            
            scale_division = scale_divisions || (scale_range / 10.0)
            
            if scale_integers
            scale_division = scale_division < 1 ? 1 : scale_division.round
            end
            
            rv = []
            maxvalue = maxvalue%scale_division == 0 ? 
            maxvalue : maxvalue + scale_division
            minvalue.step( maxvalue, scale_division ) {|v| rv << v}
            return rv
		end
		
        def unit_width
            (@graph_width-(@inner_margin*2)) / (@histogram.max-@histogram.min).to_f
        end
        def draw_x_label(v)
            left = (v - @histogram.min)*unit_width                    
            x=@inner_margin+left
            text = @graph.add_element( "text" )
            text.attributes["class"] = "xAxisLabels"
            text.text = sprintf("%0.2f",v)
            y = @graph_height + x_label_font_size + 3
            text.attributes["x"] = x.to_s
            text.attributes["y"] = y.to_s
            
        end
	    def draw_x_labels
            if show_x_labels
                (0...@histogram.bins).each { |i|
                    value = @histogram[i]
                    range = @histogram.get_range(i)
                    draw_x_label(range[0])
                    if(i==(@histogram.bins)-1)
                        draw_x_label(range[1])
                    end
                }
            end
        end
		def draw_data
            minvalue = min_value
            fieldwidth = field_width
    
            unit_size =  (@graph_height.to_f - font_size*2*top_font) / 
                          (get_y_labels.max - get_y_labels.min)		
            bottom = @graph_height
            field_count = 0
            hist_min=@histogram.min
            hist_max=@histogram.max
            range_hist=hist_max-hist_min
            total=0
            (0...@histogram.bins).each { |i|
                dataset_count = 0
                value = @histogram[i]
                total=total+value
                range = @histogram.get_range(i)
                left = (range[0] - hist_min)*unit_width
                bar_width = (range[1] - hist_min)*unit_width - left
                length = (value.abs - (minvalue > 0 ? minvalue : 0)) * unit_size
                # top is 0 if value is negative
                top = bottom - (((value < 0 ? 0 : value) - minvalue) * unit_size)
                @graph.add_element( "rect", {
                    "x" => (@inner_margin+left).to_s,
                    "y" => top.to_s,
                    "width" => bar_width.to_s,
                    "height" => length.to_s,
                    "class" => "fill#{dataset_count+1}"
                })
                make_datapoint_text(left + @inner_margin+ (bar_width/2), top - 6, value.to_s)
                field_count += 1
            }
            if(show_normal)
                divs=30
                path=""
                0.upto(divs) {|i|
                    x_abs=hist_min+(range_hist/divs)*i
                    y=GSL::Ran::gaussian_pdf((x_abs-mean) / sigma)*total
                    xg=@inner_margin+((x_abs-hist_min)*unit_width)
                    yg=bottom-y*unit_size
                    if i==0
                        path="M#{xg} #{yg} "
                    else
                        path+="L#{xg} #{yg} "
                    end
                }
                @graph.add_element("path", {
                        "d"=>path,
                        "style"=>"stroke:black;fill:none"
                }
                )
            end
	end
    
    
     def get_css
        return <<EOL
/* default fill styles for multiple datasets (probably only use a single dataset on this graph though) */

.key1,.fill1{
	fill: #ff0000;
	stroke: black;
	stroke-width: 1px;	
}
.key2,.fill2{
	fill: #0000ff;
	stroke: black;
	stroke-width: 1px;	
}
.key3,.fill3{
	fill: #00ff00;
	stroke: none;
	stroke-width: 1px;	
}
.key4,.fill4{
	fill: #ffcc00;
	stroke: none;
	stroke-width: 1px;	
}
.key5,.fill5{
	fill: #00ccff;
	stroke: none;
	stroke-width: 1px;	
}
.key6,.fill6{
	fill: #ff00ff;
	stroke: none;
	stroke-width: 1px;	
}
.key7,.fill7{
	fill: #00ffff;
	stroke: none;
	stroke-width: 1px;	
}
.key8,.fill8{
	fill: #ffff00;
	stroke: none;
	stroke-width: 1px;	
}
.key9,.fill9{
	fill: #cc6666;
	stroke: none;
	stroke-width: 1px;	
}
.key10,.fill10{
	fill: #663399;
	stroke: none;
	stroke-width: 1px;	
}
.key11,.fill11{
	fill: #339900;
	stroke: none;
	stroke-width: 1px;	
}
.key12,.fill12{
	fill: #9966FF;
	stroke: none;
	stroke-width: 1px;	
}
EOL
      	end

end
end
end
