require "test/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"
require 'hpricot'
require 'tempfile'
class TestReportbuilder < Test::Unit::TestCase
  def setup
    @datadir=File.dirname(__FILE__)+"/../data"
    @image=@datadir+"/sheep.jpg"
  end
  # adding basic object
  def test_basic_generators
    # basic_classes = Array,String,Integer, Float,Time,Hash
    args=[]
    args << [1,2,3]
    args << "1,2,3"
    args << 1
    args << 1.0
    args << 1.quo(2)
    args << Time.new
    args << {'a'=>1,'b'=>2}
    rb=ReportBuilder.new
    args.each do |a|
      assert_nothing_raised do
        rb.add(a)
      end
    end
  end
  def test_proc
    
    a=lambda {|g|
      g.text "texto"
      g.preformatted "pre"
      g.table(:header=>%w{a b}) {row([1,2]); row([1,3])}
      g.image @image
    }
    rb=ReportBuilder.new
    rb.add(a)
    rb.to_text
  end
  def test_empty
    rp=ReportBuilder.new
    assert_match(/^Report.+\n$/,rp.to_s)
    rp=ReportBuilder.new(:no_title=>true)
    assert_equal("",rp.to_s)
    rp.add("hola")
    assert_equal("hola\n",rp.to_s)
  end
  def test_generate
    res=ReportBuilder.generate(:format=>:text,:name=>"Test") do
      text("hola")
    end
    assert_match(/^Test\nhola$/,res)
    html_file=Tempfile.new("test.html")
    html=ReportBuilder.generate(:name=>"Test", :format=>:html) do
      text("hola")
    end
    ReportBuilder.generate(:name=>"Test", :filename=>html_file,:format=>:html) do
      text("hola")
    end
    
    assert_equal(html,File.read(html_file.path))
    
  end
end
