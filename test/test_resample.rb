require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleResampleTestCase < Minitest::Test
  def initialize(*args)
    super
  end

  def test_basic
    r = Statsample::Resample.generate(20, 1, 10)
    assert_equal(20, r.size)
    assert(r.min >= 1)
    assert(r.max <= 10)
  end

  def test_repeat_and_save
    r = Statsample::Resample.repeat_and_save(400) {
      Statsample::Resample.generate(20, 1, 10).count(1)
    }
    assert_equal(400, r.size)
    v = Daru::Vector.new(r)
    a = v.count { |x|  x > 3 }
    assert(a >= 30 && a <= 70)
  end
end
