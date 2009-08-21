$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'tmpdir'
require 'tempfile'
require 'fileutils'
require 'test/unit'
begin
	require 'statsample/graph/svggraph'
class StatsampleSvgGraphTestCase < Test::Unit::TestCase

	def initialize(*args)
        @image_path=Dir::tmpdir+"/images"
        FileUtils.mkdir(@image_path) if !File.exists? @image_path 
		super
	end
    def test_histogram
        if HAS_GSL
        ar=(1..1000).to_a.collect {|a|
			rand(10)
		}.to_vector(:scale)
        h=ar.histogram([0,2,5,11])
        file=@image_path+"/svg_histogram_only.svg"
        graph = Statsample::Graph::SvgHistogram.new({})
        graph.histogram=h
        File.open(file,"w") {|f|
              f.puts(graph.burn)
        }
	else
		puts "Statsample::Graph::SvgHistogram.new not tested (no ruby-gsl)"
	end
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
		if HAS_GSL
		file=@image_path+"/svggraph_histogram.svg"		
		hist=vector.svggraph_histogram(5)
		File.open(file,"wb") {|fp|
            fp.write(hist.burn)
		}
		assert(File.exists?(file))
		else
		puts "Statsample::Vector#svggraph_histogram.new not tested (no ruby-gsl)"

		end
	end
end
rescue LoadError
	puts "You should install SVG::Graph"
end
