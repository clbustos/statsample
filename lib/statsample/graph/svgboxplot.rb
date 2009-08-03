module Statsample
    module Graph
        class SvgBoxplot < SVG::Graph::Bar
            def initialize(config={})
                config[:fields]=["dummy"]
                super(config)
            end
            def get_x_labels
                @data.collect{|d|
                    d[:title]
                }
            end
            
            def min_value
                min = 0
                if min_scale_value.nil? 
                    min = @data.collect{|x| x[:data].min}.min
                    if min > 0
                        if min > 10
                            min=min-2
                        else
                            min=0
                        end
                    end
                else
                    min = min_scale_value
                end
                return min
            end
            def draw_data
            minvalue = min_value
            fieldwidth = field_width
            unit_size =  (@graph_height.to_f - font_size*2*top_font) / 
                          (get_y_labels.max - get_y_labels.min)
            bargap = bar_gap ? (fieldwidth < 10 ? fieldwidth / 2 : 10) : 0
            
            bar_width = fieldwidth - bargap
            bar_width /= @data.length if stack == :side
            x_mod = (@graph_width-bargap) / 2 - (stack==:side ? bar_width/2 : 0)
            
            bottom = @graph_height
            
            field_count = 0
            for dataset in @data
            
            # cases (assume 0 = +ve):
            #   value  min  length
            #    +ve   +ve  value - min
            #    +ve   -ve  value - 0
            #    -ve   -ve  value.abs - 0
            
            min=dataset[:data].min
            max=dataset[:data].max
            median=dataset[:vector].median
            q1=dataset[:vector].percentil(25)
            q3=dataset[:vector].percentil(75)
            iqr=q3-q1
            left = (fieldwidth * field_count)
            #length = (value.abs - (minvalue > 0 ? minvalue : 0)) * unit_size
            # top is 0 if value is negative
            top_wisk=(q3+iqr*1.5 < max) ? q3+iqr*1.5 : max
            down_wisk= (q1-iqr*1.5 > min) ? q1-iqr*1.5 : min
            
            top=@graph_height-((top_wisk-minvalue)*unit_size)
            down=@graph_height-((down_wisk-minvalue)*unit_size)
            
            median_bar=@graph_height-((median-minvalue)*unit_size)
            middle= left+(bar_width / 2)
            left_whis=left+(bar_width * 0.4)
            rigth_whis=left+(bar_width*0.6)
            left_rect= left+(bar_width * 0.25)
            rigth_rect = left+ (bar_width * 0.75)
            top_rect=@graph_height-((q3-minvalue)*unit_size)
            height_rect=iqr*unit_size
            path="M #{left_whis} #{top} H #{rigth_whis} M #{middle} #{top} V #{down} M #{left_whis} #{down} H #{rigth_whis} M #{left_rect} #{median_bar} H #{rigth_rect}"
            
            
            # Marcamos Outliers
            if top_wisk!=max or down_wisk!=min
                dataset[:vector].valid_data.each{|d|
                    if(d<down_wisk) or (d>top_wisk)
                    y_out=(@graph_height - (d -minvalue)*unit_size).to_s
                        @graph.add_element( "circle", {
                         "cx" => (middle).to_s,
                         "cy" => y_out,
                        "r" => "3",
                        "class" => "dataPoint#{field_count+1}"
                        })
                        @graph.add_element( "text", {
                        "x" => (middle+20).to_s,
                        "y" => y_out,
                        "class" => "dataPointLabel",
                        "style" => "#{style} stroke: #000;"
                        }).text = d.to_s                    end
                }
            end
            
            @graph.add_element( "rect", { "x" => left_rect.to_s, "y" => top_rect.to_s, "width" => (bar_width / 2).to_s, "height" => (height_rect).to_s, "class" => "fill#{field_count+1}"})

            @graph.add_element("path",{"d"=>path, "style"=>"stroke:black;stroke-width:2"})
            
            field_count += 1
            end
           
            end
        end
    end
end
