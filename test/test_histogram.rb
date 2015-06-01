require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleHistogramTestCase < Minitest::Test
  context Statsample::Histogram do
    should 'alloc correctly with integer' do
      h = Statsample::Histogram.alloc(4)
      assert_equal([0.0] * 4, h.bin)
      assert_equal([0.0] * 5, h.range)
    end
    should 'alloc correctly with array' do
      h = Statsample::Histogram.alloc([1, 3, 7, 9, 20])
      assert_equal([0.0] * 4, h.bin)
      assert_equal([1, 3, 7, 9, 20], h.range)
    end
    should 'alloc correctly with integer and min, max array' do
      h = Statsample::Histogram.alloc(5, [0, 5])
      assert_equal([0.0, 1.0, 2.0, 3.0, 4.0, 5.0], h.range)
      assert_equal([0.0] * 5, h.bin)
    end
    should 'bin() method return correct number of bins' do
      h = Statsample::Histogram.alloc(4)
      assert_equal(4, h.bins)
    end
    should 'increment correctly' do
      h = Statsample::Histogram.alloc(5, [0, 5])
      h.increment 2.5
      assert_equal([0.0, 0.0, 1.0, 0.0, 0.0], h.bin)
      h.increment [0.5, 0.5, 3.5, 3.5]
      assert_equal([2.0, 0.0, 1.0, 2.0, 0.0], h.bin)
      h.increment 0
      assert_equal([3.0, 0.0, 1.0, 2.0, 0.0], h.bin)
      h.increment 5
      assert_equal([3.0, 0.0, 1.0, 2.0, 0.0], h.bin)
    end

    should 'alloc_uniform correctly with n, min,max' do
      h = Statsample::Histogram.alloc_uniform(5, 0, 10)
      assert_equal(5, h.bins)
      assert_equal([0.0] * 5, h.bin)
      assert_equal([0.0, 2.0, 4.0, 6.0, 8.0, 10.0], h.range)
    end
    should 'alloc_uniform correctly with n, [min,max]' do
      h = Statsample::Histogram.alloc_uniform(5, [0, 10])
      assert_equal(5, h.bins)
      assert_equal([0.0] * 5, h.bin)
      assert_equal([0.0, 2.0, 4.0, 6.0, 8.0, 10.0], h.range)
    end
    should 'get_range()' do
      h = Statsample::Histogram.alloc_uniform(5, 2, 12)
      5.times {|i|
        assert_equal([2 + i * 2, 4 + i * 2], h.get_range(i))
      }
    end
    should 'min() and max()' do
      h = Statsample::Histogram.alloc_uniform(5, 2, 12)
      assert_equal(2, h.min)
      assert_equal(12, h.max)
    end
    should 'max_val()' do
      h = Statsample::Histogram.alloc(5, [0, 5])
      100.times { h.increment(rand * 5) }
      max = h.bin[0]
      (1..4).each {|i|
        max = h.bin[i] if h.bin[i] > max
      }
      assert_equal(max, h.max_val)
    end
    should 'min_val()' do
      h = Statsample::Histogram.alloc(5, [0, 5])
      100.times { h.increment(rand * 5) }
      min = h.bin[0]
      (1..4).each {|i|
        min = h.bin[i] if h.bin[i] < min
      }
      assert_equal(min, h.min_val)
    end
    should 'return correct estimated mean' do
      a = Daru::Vector.new([1.5, 1.5, 1.5, 3.5, 3.5, 3.5])
      h = Statsample::Histogram.alloc(5, [0, 5])
      h.increment(a)
      assert_equal(2.5, h.estimated_mean)
    end
    should 'return correct estimated standard deviation' do
      a = Daru::Vector.new([0.5, 1.5, 1.5, 1.5, 2.5, 3.5, 3.5, 3.5, 4.5])
      h = Statsample::Histogram.alloc(5, [0, 5])
      h.increment(a)
      assert_equal(a.sd, h.estimated_standard_deviation)
    end
    should 'return correct sum for all values' do
      h = Statsample::Histogram.alloc(5, [0, 5])
      n = rand(100)
      n.times { h.increment(1) }
      assert_equal(n, h.sum)
    end
    should 'return correct sum for a subset of values' do
      h = Statsample::Histogram.alloc(5, [0, 5])
      h.increment([0.5, 2.5, 4.5])
      assert_equal(1, h.sum(0, 1))
      assert_equal(2, h.sum(1, 4))
    end
    should 'not raise exception when all values equal' do
      assert_nothing_raised do
        a = Daru::Vector.new([5, 5, 5, 5, 5, 5])
        h = Statsample::Graph::Histogram.new(a)
        h.to_svg
      end
    end
  end
end
