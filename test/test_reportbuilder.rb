require "test/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"

class TestReportbuilder < Test::Unit::TestCase
  # adding basic object
  def test_basic_generators
    # basic_classes = Array,String,Integer, Float,Time,Hash
    ary=[1,2,3]
    str="1,2,3"
    int=1
    flt=1.0
    rat=1.quo(2)
    tim=Time.new
    has={'a'=>1,'b'=>2}
    rb=ReportBuilder.new
    rb.add(ary,str,int,flt,rat,tim,has)
    assert_nothing_raised do
      rb.to_s
    end
  end
end
