require "minitest/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"
require 'reportbuilder/table/htmlgenerator'
require 'reportbuilder/table/textgenerator'
require 'nokogiri'

MiniTest::Unit.autorun
class TestReportbuilderTable < MiniTest::Unit::TestCase
  def setup
    super
    @name="Table Test"
    @header=%w{a bb ccc dddd eeee fff gggg hh i}
    table=ReportBuilder::Table.new(:name=>"Table Test", :header=>@header) do
      row(["a","b","c","d","e","f","g","h","i"])
      row([colspan("a",2),nil,"c",rowspan("d",2),"e","f","g","h","i"])
      row([colspan("a",3),nil,nil,nil,"e","f","g","h","i"])
      row([colspan("a",4),nil,nil,nil,"e","f","g","h","i"])
      row([colspan("a",5),nil,nil,nil,nil,colspan("f",3),nil,nil,"i"])
      row([colspan("a",6),nil,nil,nil,nil,nil,"g","h","i"])
    end
    
    @table=table

    @mock_generator = ""
    class << @mock_generator
      def preformatted(t)
        replace(t)
      end
      def text(t)
        replace(t)
      end
      def table_entry(t)
        "MOCK"
      end
      def html(t)
        replace(t)
      end
    end

  end
  def test_empty_table
    text=ReportBuilder.generate(:no_title=>true,:format=>:text) do
      table(:name=>"Table")
    end
    assert_match(/^Table\s+$/ , text)
  end
  def test_table_text

    tg=ReportBuilder::Table::TextGenerator.new(@mock_generator,@table)
    tg.generate
        expected= <<-HEREDOC
Table Test
----------------------------------------------------
| a | bb | ccc | dddd | eeee | fff | gggg | hh | i |
----------------------------------------------------
| a | b  | c   | d    | e    | f   | g    | h  | i |
| a      | c   | d    | e    | f   | g    | h  | i |
| a            |      | e    | f   | g    | h  | i |
| a                   | e    | f   | g    | h  | i |
| a                          | f               | i |
| a                                | g    | h  | i |
----------------------------------------------------
HEREDOC

    assert_equal(expected,@mock_generator)

  end
  def test_table_html

    tg=ReportBuilder::Table::HtmlGenerator.new(@mock_generator,@table)
    tg.generate
    
    expected= <<HEREDOC
<a name='MOCK'> </a>
<table>
    <thead>
    <th>a</th><th>bb</th><th>ccc</th>
    <th>dddd</th><th>eeee</th>
    <th>fff</th><th>gggg</th><th>hh</th><th>i</th>
    </thead>
    <tbody>
    <tr><td>a</td><td>b</td><td>c</td><td>d</td><td>e</td>
    <td>f</td><td>g</td><td>h</td><td>i</td></tr>
    
    <tr><td colspan="2">a</td><td>c</td><td rowspan="2">d</td><td>e</td>
    <td>f</td><td>g</td><td>h</td><td>i</td></tr>
    
    <tr><td colspan="3">a</td><td>e</td>
    <td>f</td><td>g</td><td>h</td><td>i</td></tr>
    
    <tr><td colspan="4">a</td><td>e</td>
    <td>f</td><td>g</td><td>h</td><td>i</td></tr>
    
    <tr><td colspan="5">a</td><td colspan="3">f</td><td>i</td></tr>
    
    <tr><td colspan="6">a</td><td>g</td><td>h</td><td>i</td></tr>
    </tbody>
    </table>
HEREDOC

    doc=Nokogiri::HTML(@mock_generator).at_xpath("/html")
    
    assert(doc.at_xpath("a[@name='MOCK']")!="")
    assert(doc.at_xpath("table")!="")
    
    assert_equal(@header, doc.xpath("//table/thead/th").map {|m| m.content} )
    [[2,%w{a}],
    [3,%w{a f}],
    [4,%w{a}],
    [5,%w{a}],
    [6,%w{a}],
    
    ].each do |m,exp|
      real=doc.xpath("//table/tbody/tr/td[@colspan='#{m}']").map {|x| x.inner_html}
      assert_equal(exp, real, "On table/tbody/tr/td[@colspan='#{m}']"
        )
    end

  end
end
