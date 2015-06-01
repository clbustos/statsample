require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleStratifiedTestCase < Minitest::Test
  def initialize(*args)
    super
  end

  def test_mean
    a = [10, 20, 30, 40, 50]
    b = [110, 120, 130, 140]
    pop = a + b
    av   = Daru::Vector.new(a)
    bv   = Daru::Vector.new(b)
    popv = Daru::Vector.new(pop)
    assert_equal(popv.mean, Statsample::StratifiedSample.mean(av, bv))
  end
end
