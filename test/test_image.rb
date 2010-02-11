require "test/unit"
$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"

class TestReportbuilderImage < Test::Unit::TestCase
  def setup
    @tmpdir=Dir::mktmpdir
    @rp=ReportBuilder.new("Test", @tmpdir)
    @datadir=File.dirname(__FILE__)+"/../data"
    @rp.add(@rp.image(@datadir+"/sheep.jpg"))
  end
  def teardown
   FileUtils.remove_entry_secure @tmpdir
  end
  def test_image_text
    expected= <<-HERE
Report: Test
+--------------------------------+
|          *********#**          |
|         ****#********#    *    |
|  * *  *********#*******     *  |
|           * ***  ***   *      *|
|     * *    WWW WW*     ***     |
|    ****   *WW* WWW *   **#*    |
|    ****   *        *   ****    |
|    *****  #       **  *#***    |
|    ****** **      *  *#****    |
|     ******        ********     |
|     *******   **   ******      |
|       **#***   * *******       |
|        ****#**  *#*****        |
|             **#*****           |
+--------------------------------+
HERE
puts @rp.to_s
  assert_equal(expected, @rp.to_s)
  end
  def test_image_html
    assert_match(/img src='images\/sheep.jpg'/, @rp.to_html)
  end
  
end
