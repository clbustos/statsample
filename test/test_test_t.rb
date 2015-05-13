require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleTestTTestCase < Minitest::Test
  include Statsample::Test
  include Math
  context T do
    setup do
      @a = [30.02, 29.99, 30.11, 29.97, 30.01, 29.99].to_numeric
      @b = [29.89, 29.93, 29.72, 29.98, 30.02, 29.98].to_numeric
      @x1 = @a.mean
      @x2 = @b.mean
      @s1 = @a.sd
      @s2 = @b.sd
      @n1 = @a.n
      @n2 = @b.n
    end
    should 'calculate correctly standard t' do
      t = Statsample::Test::T.new(@x1, @s1.quo(Math.sqrt(@a.n)), @a.n - 1)
      assert_equal((@x1).quo(@s1.quo(Math.sqrt(@a.n))), t.t)
      assert_equal(@a.n - 1, t.df)
      assert(t.summary.size > 0)
    end
    should 'calculate correctly t for one sample' do
      t1 = [6, 4, 6, 7, 4, 5, 5, 12, 6, 1].to_numeric
      t2 = [9, 6, 5, 10, 10, 8, 7, 10, 6, 5].to_numeric
      d = t1 - t2
      t = Statsample::Test::T::OneSample.new(d)
      assert_in_delta(-2.631, t.t, 0.001)
      assert_in_delta(0.027, t.probability, 0.001)
      assert_in_delta(0.76012, t.se, 0.0001)
      assert(t.summary.size > 0)
    end
    should 'calculate correctly t for two samples' do
      assert_in_delta(1.959, T.two_sample_independent(@x1, @x2, @s1, @s2, @n1, @n2), 0.001)
      assert_in_delta(1.959, T.two_sample_independent(@x1, @x2, @s1, @s2, @n1, @n2, true), 0.001)
    end
    should 'calculate correctly df for equal and unequal variance' do
      assert_equal(10,  T.df_equal_variance(@n1, @n2))
      assert_in_delta(7.03,  T.df_not_equal_variance(@s1, @s2, @n1, @n2), 0.001)
    end
    should 'calculate all values for T object' do
      t = Statsample::Test.t_two_samples_independent(@a, @b)
      assert(t.summary.size > 0)
      assert_in_delta(1.959, t.t_equal_variance, 0.001)
      assert_in_delta(1.959, t.t_not_equal_variance, 0.001)
      assert_in_delta(10, t.df_equal_variance, 0.001)
      assert_in_delta(7.03, t.df_not_equal_variance, 0.001)
      assert_in_delta(0.07856, t.probability_equal_variance, 0.001)
      assert_in_delta(0.09095, t.probability_not_equal_variance, 0.001)
    end
    should 'be the same using shorthand' do
      v = 100.times.map { rand(100) }.to_numeric
      assert_equal(Statsample::Test.t_one_sample(v).t, T::OneSample.new(v).t)
    end
    should 'calculate all values for one sample T test' do
      u = @a.mean + (1 - rand * 2)
      tos = T::OneSample.new(@a, u: u)
      assert_equal((@a.mean - u).quo(@a.sd.quo(sqrt(@a.n))), tos.t)
      assert_equal(@a.n - 1, tos.df)
      assert(tos.summary.size > 0)
    end
  end
end
