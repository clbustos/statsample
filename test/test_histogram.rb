require(File.dirname(__FILE__)+'/test_helpers.rb')



class StatsampleHistogramTestCase < Test::Unit::TestCase
  def test_control
    h = Statsample::Histogram.alloc(4)
    assert_equal([0.0]*4, h.bin)
    assert_equal([0.0]*5, h.range)
    h = Statsample::Histogram.alloc([1, 3, 7, 9, 20])
    assert_equal([0.0]*4, h.bin)
    assert_equal([1,3,7,9,20], h.range)
    h = Statsample::Histogram.alloc(5, [0, 5])
    assert_equal([0.0,1.0,2.0,3.0,4.0,5.0], h.range)
    assert_equal([0.0]*5,h.bin)
    h.increment(2.5)
    assert_equal([0.0,0.0,1.0,0.0,0.0], h.bin)
    h.increment([0.5,0.5,3.5,3.5])
    assert_equal([2.0,0.0,1.0,2.0,0.0], h.bin)
    h.increment(0)
    assert_equal([3.0,0.0,1.0,2.0,0.0], h.bin)
    h.increment(5)
    assert_equal([3.0,0.0,1.0,2.0,0.0], h.bin)
  end
end
