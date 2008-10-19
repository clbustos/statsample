require File.dirname(__FILE__)+'/../lib/rubyss'
require 'tempfile'
require 'test/unit'
require 'rubyss/graph/svggraph'

# Not included on default test, because GDChart send a lot of warnings!
class RubySSSvgGraphTestCase < Test::Unit::TestCase

	def initialize(*args)
		@image_path=File.dirname(__FILE__)+"/images"
		super
	end
    def test_histogram
        
        ar=(1..1000).to_a.collect {|a|
			rand(10)
		}.to_vector(:scale)
        h=ar.histogram([0,2,5,11])
        file=@image_path+"/svg_histogram_only.svg"
        graph = RubySS::Graph::SvgHistogram.new(:graph_title=>"Histograma")
        graph.histogram=h
        File.open(file,"w") {|f|
              f.puts(graph.burn)
        }
    end
    def test_vector
		file=@image_path+"/gdchart_bar.jpg"
		ar=[]
		(1..1000).each {|a|
			ar.push(rand(10))
		}
		vector=ar.to_vector
        file=@image_path+"/svggraph_default.svg"
		vector.svggraph_frequencies(file)
        
		file=@image_path+"/svggraph_Bar.svg"
		vector.svggraph_frequencies(file,800,600,SVG::Graph::Bar,:graph_title=>'Bar')
		assert(File.exists?(file))
		file=@image_path+"/svggraph_BarHorizontal.svg"
		vector.svggraph_frequencies(file,800,600,SVG::Graph::BarHorizontalNoOp,:graph_title=>'Horizontal Bar')
		assert(File.exists?(file))
		file=@image_path+"/svggraph_Pie.svg"
		vector.svggraph_frequencies(file,800,600,SVG::Graph::PieNoOp,:graph_title=>'Pie')
		assert(File.exists?(file))		
		vector.type=:scale
		file=@image_path+"/svggraph_histogram.svg"		
		vector.svggraph_histogram(5,file,600,400)
		assert(File.exists?(file))
	end
end