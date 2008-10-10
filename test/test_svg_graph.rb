require File.dirname(__FILE__)+'/../lib/rubyss'
require 'tempfile'
require 'test/unit'
require 'rubyss/chart/svgchart'

require 'SVG/Graph/Graph.rb'

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
        file=@image_path+"/svgchart_default.svg"
		vector.svgchart_frequencies(file)
        file=@image_path+"/svgchart_default.png"
		vector.svgchart_frequencies(file,500,400,SVG::Graph::Bar)
        
		file=@image_path+"/svgchart_Bar.svg"
		vector.svgchart_frequencies(file,800,600,SVG::Graph::Bar,:graph_title=>'Bar')
		assert(File.exists?(file))
		file=@image_path+"/svgchart_BarHorizontal.svg"
		vector.svgchart_frequencies(file,800,600,SVG::Graph::BarHorizontal,:graph_title=>'Horizontal Bar')
		assert(File.exists?(file))
		vector.type=:scale
		file=@image_path+"/svgchart_histogram.svg"		
		vector.svgchart_histogram(5,file,300,400,SVG::Graph::Bar,:graph_title=>'Histogram')
		assert(File.exists?(file))
	end
end