require 'SVG/Graph/Bar'
require 'SVG/Graph/BarHorizontal'
require 'SVG/Graph/Pie'
require 'SVG/Graph/Line'
require 'rubyss/graph/svghistogram.rb'
module RubySS
    
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
            options={:height=>height,:width=>width, :graph_title=>"Histogram", :show_graph_title=>true}.merge! options
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
