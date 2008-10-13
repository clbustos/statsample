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

    def test_vector
		file=@image_path+"/gdchart_bar.jpg"
		ar=[]
		(1..1000).each {|a|
			ar.push(rand(10))
		}
		vector=ar.to_vector
        file=@image_path+"/svggraph_default.svg"
		vector.svggraph_frequencies(file)
        file=@image_path+"/svggraph_default.png"
		vector.svggraph_frequencies(file)
        
		file=@image_path+"/svggraph_Bar.svg"
		vector.svggraph_frequencies(file,800,600,SVG::Graph::BarNoOp,:graph_title=>'Bar')
		assert(File.exists?(file))
		file=@image_path+"/svggraph_BarHorizontal.svg"
		vector.svggraph_frequencies(file,800,600,SVG::Graph::BarHorizontalNoOp,:graph_title=>'Horizontal Bar')
		assert(File.exists?(file))
		file=@image_path+"/svggraph_Pie.svg"
		vector.svggraph_frequencies(file,800,600,SVG::Graph::PieNoOp,:graph_title=>'Pie')
		assert(File.exists?(file))		
		vector.type=:scale
		file=@image_path+"/svggraph_histogram.svg"		
		vector.svggraph_histogram(5,file,300,400,RubySS::Graph::SvgHistogram,:graph_title=>'Histogram')
		assert(File.exists?(file))
	end
end