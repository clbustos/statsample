require(File.dirname(__FILE__)+'/helpers_tests.rb')
require('statsample/graph')
class StatsampleSvgGraphTestCase < MiniTest::Unit::TestCase

  def setup
    @image_path=Dir::tmpdir+"/images"
    FileUtils.mkdir(@image_path) if !File.exists? @image_path
  end
  def test_histogram
    if Statsample.has_gsl?
      ar=(1..1000).to_a.collect {|a|
        rand(10)
      }.to_vector(:scale)
      h=ar.histogram([0,2,5,11])
      file=Tempfile.new("svg_histogram_only.svg")
      graph = Statsample::Graph::SvgHistogram.new({})
      graph.histogram=h
      file.puts(graph.burn)
    else
      skip "Statsample::Graph::SvgHistogram.new not tested (no ruby-gsl)"
    end
  end
  def assert_svg(msg=nil)
    msg||="%s isn't a svg file"
    Tempfile.open("svg") do |fp|
      yield fp
      fp.close
      fp.open
      assert_match(/DOCTYPE svg/, fp.gets(nil), sprintf(msg,fp.path))
    end
  end
  def test_vector
    ar=[]
    (1..1000).each {|a|
      ar.push(rand(10))
    }
    vector=ar.to_vector
    assert_svg {|file| vector.svggraph_frequencies(file)}
    assert_svg {|file| vector.svggraph_frequencies(file, 800, 600, SVG::Graph::Bar, :graph_title=>'Bar') }
    assert_svg {|file| vector.svggraph_frequencies(file, 800, 600, SVG::Graph::BarHorizontalNoOp, :graph_title=>'Horizontal Bar') }
    assert_svg {|file| vector.svggraph_frequencies(file,800,600, SVG::Graph::PieNoOp, :graph_title=>'Pie') }
    vector.type=:scale
    if Statsample.has_gsl?
      file=Tempfile.new("svg_histogram.svg").path
      hist=vector.svggraph_histogram(5)
      File.open(file,"wb") {|fp|
        fp.write(hist.burn)
      }
      #assert(File.exists?(file))
    else
      skip "Statsample::Vector#svggraph_histogram.new not tested (no ruby-gsl)"
    end
  end
end
