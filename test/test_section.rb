require "test/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"

class TestReportbuilderSection < Test::Unit::TestCase
  def setup
    @rp=ReportBuilder.new("Test Report")
    s1=@rp.section("Section 1")
    @rp.add s1
    s1.add("Texto 1")
    s1.add(2)
    s11=@rp.section("Section 1.1")
    s1.add s11
    s1.add("Texto 1.1")
    s2=@rp.section("Section 2")
    @rp.add s2
  end
  def test_section_text
    expected= <<-HERE
Report: Test Report
  = Section 1
    Texto 1
    2
    == Section 1.1
    Texto 1.1
  = Section 2

HERE
  assert_equal(expected, @rp.to_s)
  end
  def test_section_html
    expected= <<-HERE
<html><head><title>Test Report</title></head><body>
<h1>Test Report</h1><div class='toc'><div class='title'>List of contents</div></div><ul>
<li><a href='#toc_1'>Section 1</a></li>
<ul>
<li><a href='#toc_2'>Section 1.1</a></li>
</ul>
<li><a href='#toc_3'>Section 2</a></li>
</ul>
</div>
    <div class='section'><h2>Section 1</h2><a name='toc_1'></a>
<pre>Texto 1</pre>
<pre>2</pre>
        <div class='section'><h3>Section 1.1</h3><a name='toc_2'></a>
        </div>
<pre>Texto 1.1</pre>
    </div>
    <div class='section'><h2>Section 2</h2><a name='toc_3'></a>
    </div>
</body></html>
HERE
  assert_equal(expected.gsub(/\s/,""), @rp.to_html.gsub(/\s/,""))
  end
  
end
