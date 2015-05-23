require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
require 'ostruct'
class StatsampleGGobiTestCase < Minitest::Test
  def setup
    v1  = Daru::Vector.new([10.2, 20.3, 10, 20, 30, 40, 30, 20, 30, 40] * 10)
    @v2 = Daru::Vector.new(%w(a b c a a a b b c d) * 10)
    @v2.labels = { 'a' => 'letter a', 'd' => 'letter d' }
    v3  = Daru::Vector.new([1, 2, 3, 4, 5, 4, 3, 2, 1, 2] * 10)
    @ds = Daru::DataFrame.new({ :v1 => v1, :v2 => @v2, :v3 => v3 })
  end

  def test_values_definition
    a = [1.0, 2, 'a', nil]
    assert_equal('1.0 2 a NA', Statsample::GGobi.values_definition(a, 'NA'))
  end

  def test_variable_definition
    carrier = OpenStruct.new
    carrier.categorials = []
    carrier.conversions = {}
    real_var_definition = Statsample::GGobi.variable_definition(carrier, @v2, 'variable 2', 'v2')
    expected = <<-EOS
<categoricalvariable name="variable 2" nickname="v2">
<levels count="4">
<level value="1">letter a</level>
<level value="2">b</level>
<level value="3">c</level>
<level value="4">letter d</level></levels>
</categoricalvariable>
    EOS
    assert_equal(expected.gsub(/\s/, ' '), real_var_definition.gsub(/\s/, ' '))
    assert_equal({ 'variable 2' => { 'a' => 1, 'b' => 2, 'c' => 3, 'd' => 4 } }, carrier.conversions)
    assert_equal(['variable 2'], carrier.categorials)
  end
end
