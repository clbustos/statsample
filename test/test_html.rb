require "test/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"
require 'fileutils'
require 'tmpdir'
class TestReportbuilderHtml < Test::Unit::TestCase
  def setup
    @tmpdir=Dir::mktmpdir
    @rp=ReportBuilder.new("Test Html", @tmpdir)
    @datadir=File.dirname(__FILE__)+"/../data"
  end
  def teardown
   FileUtils.remove_entry_secure @tmpdir
  end
  def test_include_js
    mock_element = ""
    eval(" class << mock_element 
      def to_rb_html(generator)
        generator.add_js('"+@datadir+"/test.js')
      end
    end ")
    @rp.add(mock_element)
    assert_match(/script.+js\/test.js/, @rp.to_html)
    assert(File.exists? @tmpdir+"/js/test.js")
  end
  def test_save_html
    exp=@rp.to_html
    @rp.save_html("test.html")
    obt=""
    File.open(@tmpdir+"/test.html","r") {|fp|
      obt=fp.readlines(nil)[0]
    }
    assert_equal(exp,obt)
  end
  def test_include_css
    mock_element = ""
    eval(" class << mock_element 
      def to_rb_html(generator)
        generator.add_css('"+@datadir+"/test.css')
      end
    end ")
    @rp.add(mock_element)
    assert_match(/link rel='stylesheet'.+css\/test.css/, @rp.to_html)
    assert(File.exists? @tmpdir+"/css/test.css")
  end  
  
end
