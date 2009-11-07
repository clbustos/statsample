require "test/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"
require "reportbuilder/table/htmlgenerator"
require "reportbuilder/table/textgenerator"

class TestReportbuilderTable < Test::Unit::TestCase
  def setup
    super
    table=ReportBuilder::Table.new(:header=>%w{a bb ccc dddd eeee fff gggg hh i})
    table.add_row(["a","b","c","d","e","f","g","h","i"])
    table.add_row([table.colspan("a",2),nil,"c",table.rowspan("d",2),"e","f","g","h","i"])
    table.add_row([table.colspan("a",3),nil,nil,nil,"e","f","g","h","i"])
    table.add_row([table.colspan("a",4),nil,nil,nil,"e","f","g","h","i"])
    table.add_row([table.colspan("a",5),nil,nil,nil,nil,table.colspan("f",3),nil,nil,"i"])
    table.add_row([table.colspan("a",6),nil,nil,nil,nil,nil,"g","h","i"])
    @table=table
    
    @mock_generator = ""
    class << @mock_generator
      def add_raw(t)
        replace(t)
      end
      def add_text(t)
        replace(t)
      end
      def add_table_entry(t)
        "MOCK"
      end
    end
    
  end
  def test_table_text
    
    tg=ReportBuilder::Table::TextGenerator.new(@mock_generator,@table)
    tg.generate
        expected= <<HEREDOC
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

assert_equal(expected.gsub(/\s/m,""), @mock_generator.gsub(/\s/m,""))
  end
end
