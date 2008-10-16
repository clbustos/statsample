require 'SVG/Graph/Bar'
require 'SVG/Graph/BarHorizontal'
require 'SVG/Graph/Pie'
require 'SVG/Graph/Line'

module RubySS
	module Graph
		class SvgHistogram < SVG::Graph::BarBase
            def initialize(config)
                config[:fields]=[:dummy]
                super
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
		include REXML
		
		# See Graph::initialize and BarBase::set_defaults
		def set_defaults 
		super
		self.top_align = self.top_font = 0
        self.key=false
        @histogram=nil
		end
		
        def histogram=(h)
            @histogram=h
            @data=[{:data=>(0...@histogram.bins).to_a.collect {|i|
                @histogram[i]
            }}]
        end
		
		def get_x_labels
            range=nil
            labels=(0...@histogram.bins).to_a.collect{|i|
                range=@histogram.get_range(i)
                range[0]
            }
            labels << range[1]
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
		
		def x_label_offset( width )
            width / 2.0
		end
	
		def draw_data
		minvalue = min_value
		fieldwidth = field_width

		unit_size =  (@graph_height.to_f - font_size*2*top_font) / 
					  (get_y_labels.max - get_y_labels.min)		
		bar_width = fieldwidth
		x_mod = (@graph_width) / 2
		
		bottom = @graph_height
		
		field_count = 0

		(0...@histogram.bins).each { |i|
		dataset_count = 0
		# cases (assume 0 = +ve):
		#   value  min  length
		#    +ve   +ve  value - min
		#    +ve   -ve  value - 0
		#    -ve   -ve  value.abs - 0
		
		value = @histogram[i]
		
		left = (fieldwidth * field_count)
		
		length = (value.abs - (minvalue > 0 ? minvalue : 0)) * unit_size
		# top is 0 if value is negative
		top = bottom - (((value < 0 ? 0 : value) - minvalue) * unit_size)
		left += bar_width * dataset_count if stack == :side
		
		@graph.add_element( "rect", {
                "x" => (left+(fieldwidth/2)).to_s,
		  "y" => top.to_s,
		  "width" => bar_width.to_s,
		  "height" => length.to_s,
		  "class" => "fill#{dataset_count+1}"
		})
		
		make_datapoint_text(left + (fieldwidth/2)+bar_width/2.0, top - 6, value.to_s)
		field_count += 1
		}
	end

end
end 
    
	class Nominal
		# Creates a barchart using ruby-gdchart
		def svggraph_frequencies(file, width=600, height=300, chart_type=SVG::Graph::BarNoOp, options={})
			labels,data=[],[]
			self.frequencies.sort.each{|k,v|
				labels.push(k.to_s)
				data.push(v) 
			}
            options[:height]=height
            options[:width]=width
            options[:fields]=labels  
			graph = chart_type.new(options)
			graph.add_data(
            :data => data,
            :title => "Frequencies"
			)
			File.open(file,"w") {|f|
              f.puts(graph.burn)
			}
		end
	end
	class Scale < Ordinal
		def svggraph_histogram(bins,file, width=600, height=300, options={})
            options={:height=>height,:width=>width, :title=>"Histogram", :show_graph_title=>true}.merge! options
            graph = RubySS::Graph::SvgHistogram.new(options)
            graph.histogram=histogram(bins)
            File.open(file,"w") {|f|
              f.puts(graph.burn)
            }
		end
	end
end

# replaces all key and fill classes with similar ones, without opacity
# this allows rendering of svg and png on rox and gqview without problems
module SVG
	module Graph
		class BarNoOp < Bar
			def get_css; SVG::Graph.get_css_standard; end
		end
		class BarHorizontalNoOp < BarHorizontal
			def get_css; SVG::Graph.get_css_standard; end
		end
		
		class LineNoOp < Line
			def get_css; SVG::Graph.get_css_standard; end
			
		end
		class PieNoOp < Pie
			def get_css; SVG::Graph.get_css_standard; end
			
		end
		class << self
		def get_css_standard
        return <<EOL
/* default fill styles for multiple datasets (probably only use a single dataset on this graph though) */
.key1,.fill1{
	fill: #ff0000;
	stroke: none;
	stroke-width: 0.5px;	
}
.key2,.fill2{
	fill: #0000ff;
	stroke: none;
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
