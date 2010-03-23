require "test/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"
require 'fileutils'
require 'tmpdir'
require 'hpricot'
require 'tempfile'
class TestReportbuilderHtml < Test::Unit::TestCase
  def setup
    @tmpdir=Dir::mktmpdir
    @title="Test #{rand(100)}"
    @rp=ReportBuilder.new(:name=>@title, :directory=>@tmpdir)
    @datadir=File.dirname(__FILE__)+"/../data"
  end
  def teardown
    FileUtils.remove_entry_secure @tmpdir
  end
  def test_empty_document
    doc=Hpricot(@rp.to_html)
    assert_equal(@title, doc.search("head/title").inner_html)
    assert_equal(@title, doc.search("body/h1").inner_html)
    assert_match(/^\s+$/, doc.search("body").inner_html.gsub(/<h1>.+<\/h1>/,""))
    
  end
  def test_generate
    html=ReportBuilder.generate(:format=>:html, :name=>@title, :directory=>@tmpdir) do 
      text("hola")
    end
    doc=Hpricot(html)
    assert_equal(@title, doc.search("head/title").inner_html)
    assert_equal(@title, doc.search("body/h1").inner_html)
    assert_equal("hola", doc.search("body/p").inner_html)
    
  end
  def test_include_js
      mock = ""
      eval(" class << mock
        def report_building_html(generator)
      generator.js('"+@datadir+"/reportbuilder.js')
      end
      end ")
      @rp.add(mock)
      assert_match(/script.+js\/reportbuilder.js/, @rp.to_html)
      assert(File.exists? @tmpdir+"/js/reportbuilder.js")
  end
  def test_save_html
    tf=Tempfile.new("sdsd.html")
    exp=@rp.to_html
    @rp.save_html(tf.path)
    obt=""
    File.open(tf.path,"r") {|fp|
      obt=fp.readlines(nil)[0]
    }
    assert_equal(exp,obt)
  end
  def test_include_css
    mock_element = ""
    eval(" class << mock_element
    def report_building_html(generator)
      generator.css('"+@datadir+"/reportbuilder.css')
    end
  end ")
  @rp.add(mock_element)
  assert_match(/link rel='stylesheet'.+css\/reportbuilder.css/, @rp.to_html)
  assert(File.exists? @tmpdir+"/css/reportbuilder.css")
  end

end
