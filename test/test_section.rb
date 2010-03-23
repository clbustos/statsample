require "test/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"
require 'hpricot'

class TestReportbuilderSection < Test::Unit::TestCase
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
    doc = Hpricot(real)
    # Sanity
    assert_equal("Test Section", doc.search("head/title").inner_html)
    # Test toc
    base_ul=doc.search("/html/body/div[@id='toc']")
    assert(base_ul!="")
    #puts base_ul
    [
    ["li/a[@href='#toc_1']","Section 1"],
    ["li/a[@href='#toc_2']","Section 1.1"],
    ["li/a[@href='#toc_3']","Section 1.1.1"],
    ["li/a[@href='#toc_4']","Section 2"]].each do |path, expected|
      inner=base_ul.search(path).inner_html
      assert_equal(expected, inner, "On #{path}")
    end
    
    [
    ["div[class='section']/h2", ["Section 1","Section 2"]],
    ["div[class='section']/h3",["Section 1.1"]],
    ["div[class='section']/h4",["Section 1.1.1"]]
    ].each do |path, expected|
    base_ul.search(path).each do |el|
      assert_equal(expected, el.inner_html, "On #{path} #{el}")
    end
    end
  end

end
