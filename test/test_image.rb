$:.unshift(File.dirname(__FILE__)+"/../lib")
require 'minitest/unit'
require 'tmpdir'
require "reportbuilder"
MiniTest::Unit.autorun
class TestReportbuilderImage < MiniTest::Unit::TestCase
  def setup
    @tmpdir=Dir::mktmpdir
    @rp=ReportBuilder.new(:no_name=>true, :directory=>@tmpdir)
    @datadir=File.dirname(__FILE__)+"/../data"
    @rp.add(ReportBuilder::Image.new(@datadir+"/sheep.jpg"))
  end
  def teardown
    FileUtils.remove_entry_secure @tmpdir
  end
  def test_image_text
    expected= <<-HERE
Test
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
  real=@rp.to_s
  #expected=expected.gsub(/[^ ]/,'-')
  assert_match(/[^\s]{12}$/,real)
  end
  def test_image_html
    assert_match(/img src='images\/sheep.jpg'/, @rp.to_html)
  end
  def test_image_rtf
    assert_match(/\\pict\\picw128\\pich112\\bliptag2403101\\jpegblip/, @rp.to_rtf)
  end
end
