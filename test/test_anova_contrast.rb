require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleAnovaContrastTestCase < Minitest::Test
  context(Statsample::Anova::Contrast) do
    setup do
      constant   = Daru::Vector.new([12, 13, 11, 12, 12])
      frequent   = Daru::Vector.new([9, 10, 9, 13, 14])
      infrequent = Daru::Vector.new([15, 16, 17, 16, 16])
      never      = Daru::Vector.new([17, 18, 12, 18, 20])
      @vectors   = [constant, frequent, infrequent, never]
      @c         = Statsample::Anova::Contrast.new(vectors: @vectors)
    end
    should 'return correct value using c' do
      @c.c([1, -1.quo(3), -1.quo(3), -1.quo(3)])
      # @c.c([1,-0.333,-0.333,-0.333])
      assert_in_delta(-2.6667, @c.psi, 0.0001)
      assert_in_delta(1.0165, @c.se, 0.0001)
      assert_in_delta(-2.623, @c.t, 0.001)
      assert_in_delta(-4.82, @c.confidence_interval[0], 0.01)
      assert_in_delta(-0.51, @c.confidence_interval[1], 0.01)
      assert(@c.summary.size > 0)
    end
    should 'return correct values using c_by_index' do
      @c.c_by_index([0], [1, 2, 3])
      assert_in_delta(-2.6667, @c.psi, 0.0001)
      assert_in_delta(1.0165, @c.se, 0.0001)
      assert_in_delta(-2.623, @c.t, 0.001)
    end
    should 'return correct values using incomplete c_by_index' do
      c1 = Statsample::Anova::Contrast.new(vectors: @vectors, c: [0.5, 0.5, -1, 0])
      c2 = Statsample::Anova::Contrast.new(vectors: @vectors, c1: [0, 1], c2: [2])
      assert_equal(c1.psi, c2.psi)
      assert_equal(c1.se, c2.se)
      assert_equal(c1.t, c2.t)
    end
  end
end
