require "minitest/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"
require 'nokogiri'
MiniTest::Unit.autorun
class TestReportbuilderSection < MiniTest::Unit::TestCase
  def setup
    @name="Test Section"
    @rp=ReportBuilder.new(:name=>"Test Section")
    s1=ReportBuilder::Section.new(:name=>"Section 1")
    @rp.add s1
    s1.add("Texto 1")
    s1.add(2)
    s11=ReportBuilder::Section.new(:name=>"Section 1.1")
    s1.add s11
    s111=ReportBuilder::Section.new(:name=>"Section 1.1.1")
    s11.add s111
    s1.add("Texto 1.1")
    s2=ReportBuilder::Section.new(:name=>"Section 2")
    @rp.add s2
  end
  def test_section_generate
    text=ReportBuilder.generate(:name=>@name,:format=>:text) {
      section(:name=>"Section 1") {
        text("Texto 1")
        text("2")
        section(:name=>"Section 1.1") {
          section(:name=>"Section 1.1.1") {
          }
        }
        text("Texto 1.1")
      }
      section(:name=>"Section 2")
    }
    assert_equal(@rp.to_text,text)
  end
  def test_section_text
    expected= <<-HERE
Test Section
= Section 1
  Texto 1
  2
  == Section 1.1
    === Section 1.1.1
  Texto 1.1
= Section 2
    HERE
    assert_equal(expected, @rp.to_s)
  end
  def test_section_html
    real=@rp.to_html
    #puts real
    base = Nokogiri::HTML(real)
    # Sanity
    doc=base.at_xpath("/html")
    assert_equal("Test Section", doc.at_xpath("head/title").content)
    # Test toc
    base_ul=doc.at_xpath("/html/body/div[@id='toc']/ul")
    assert(base_ul,"Toc have something")
    [
    ["li/a[@href='#toc_1']","Section 1"],
    ["ul/li/a[@href='#toc_2']","Section 1.1"],
    ["ul/ul/li/a[@href='#toc_3']","Section 1.1.1"],
    ["li/a[@href='#toc_4']","Section 2"]].each do |path, expected|
      assert(inner=base_ul.at_xpath(path),"#{path} should return something")
      content=inner.content
      assert_equal(expected, content, "On #{path}")
    end
    
    [
    ["div[class='section']/h2", ["Section 1","Section 2"]],
    ["div[class='section']/h3",["Section 1.1"]],
    ["div[class='section']/h4",["Section 1.1.1"]]
    ].each do |path, expected|
    base_ul.xpath(path).each do |el|
      assert_equal(expected, el.content, "On #{path} #{el}")
    end
    end
  end

end
