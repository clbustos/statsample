require "minitest/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"
require 'nokogiri'

MiniTest::Unit.autorun
class TestReportbuilderTable < MiniTest::Unit::TestCase
  def setup
    super
    @name="Table Test"
    @header=%w{a bb ccc dddd eeee fff gggg hh i}
    table=ReportBuilder::Table.new(:name=>@name, :header=>@header) do
      row(["a","b","c","d","e","f","g","h","i"])
      row([colspan("a",2),"c",'d',rowspan("e",2),rowspan("f",2),"g",rowspan("h",3),"i"])
      row([colspan("a",3),'d', "g","i"])
      row([colspan("a",4),"e","f","g","i"])
      row([colspan("a",5),colspan("f",3),"i"])
      row([colspan("a",6),"g","h","i"])
    end
    
    @table=table

    @mock_generator = ""
    class << @mock_generator
      def preformatted(t)
        @first_pre||=true
        self << "\n" unless @first_pre
        self << t
        @first=false
      end
      def text(t)
        @first_text||=:true
        self << "\n" unless @first_text==:true
        self << t
        @first_text=:false
      end
      def table_entry(t)
        "MOCK"
      end
      def html(t)
        @first_html||=true
        self << "\n" unless @first_html
        self << t
        @first=false
      end
    end

  end
  def test_empty_table
    text=ReportBuilder.generate(:no_title=>true,:format=>:text) do
      table(:name=>"Table")
    end
    assert_match(/^Table\s+$/ , text)
  end
  
  def test_rtf
    rb=ReportBuilder.new
    rb.add(@table)
    rb.save_rtf("test.rtf")
    
    
  end
  def test_table_text
    tg=ReportBuilder::Table::TextBuilder.new(@mock_generator, @table)
    tg.generate
    expected= <<-HEREDOC
Table Test
+---+----+-----+------+------+-----+------+----+---+
| a | bb | ccc | dddd | eeee | fff | gggg | hh | i |
+---+----+-----+------+------+-----+------+----+---+
| a | b  | c   | d    | e    | f   | g    | h  | i |
| a      | c   | d    | e    | f   | g    | h  | i |
| a            | d    |      |     | g    |    | i |
| a                   | e    | f   | g    |    | i |
| a                          | f               | i |
| a                                | g    | h  | i |
+---+----+-----+------+------+-----+------+----+---+
HEREDOC
#puts expected
#puts @mock_generator
    assert_equal(expected, @mock_generator)
  end
  def test_table_html

    tg=ReportBuilder::Table::HtmlBuilder.new(@mock_generator,@table)
    tg.generate
    doc=Nokogiri::HTML(@mock_generator).at_xpath("/html")
    
    assert(doc.at_xpath("a[@name='MOCK']")!="")
    assert(doc.at_xpath("table")!="")
    
    assert_equal(@header, doc.xpath("//table/thead/th").map {|m| m.content} )
    expected_contents=[
    %w{a b c d e f g h i},
    %w{a c d e f g h i},
    %w{a d g i},
    %w{a e f g i},
    %w{a f i},
    %w{a g h i}
    ]
    real_contents=doc.xpath("//table/tbody/tr").map do |tr|
      tds=tr.xpath("td").map {|m| m.content}
      
    end
    assert_equal(expected_contents, real_contents) 
    
    [
    ['colspan',2,%w{a}],
    ['colspan',3,%w{a f}],
    ['colspan',4,%w{a}],
    ['colspan',5,%w{a}],
    ['colspan',6,%w{a}],
    ['rowspan',2,%w{e f}],
    ['rowspan',3,%w{h}],    
    ].each do |attr,m,exp|
      real=doc.xpath("//table/tbody/tr/td[@#{attr}='#{m}']").map {|x| x.content}.sort
      assert_equal(exp, real, "On table/tbody/tr/td[@#{attr}='#{m}']"
        )
    end

  end
end
