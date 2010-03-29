require(File.dirname(__FILE__)+'/test_helpers.rb')

class StatsampleTestTTestCase < MiniTest::Unit::TestCase
  def setup
    @a=[30.02, 29.99, 30.11, 29.97, 30.01, 29.99].to_scale
    @b=[29.89, 29.93, 29.72, 29.98, 30.02, 29.98].to_scale
    @x1=@a.mean
    @x2=@b.mean
    @s1=@a.sd
    @s2=@b.sd
    @n1=@a.n
    @n2=@b.n
  end
  def test_t_sample_independent_t
    assert_in_delta(1.959, Statsample::Test::T.two_sample_independent(@x1, @x2, @s1, @s2, @n1, @n2))
    assert_in_delta(1.959, Statsample::Test::T.two_sample_independent(@x1, @x2, @s1, @s2, @n1, @n2,true))
  end
  def test_t_sample_independent_df
    assert_equal(10,  Statsample::Test::T.df_equal_variance(@n1,@n2))
    assert_in_delta(7.03,  Statsample::Test::T.df_not_equal_variance(@s1,@s2,@n1,@n2))    
  end
  def test_t_sample_independent_object
    t=Statsample::Test.t_two_samples_independent(@a,@b)
    assert(t.summary.size>0)
    assert_in_delta(1.959, t.t_equal_variance)
    assert_in_delta(1.959, t.t_not_equal_variance)
    assert_in_delta(10, t.df_equal_variance)
    assert_in_delta(7.03, t.df_not_equal_variance)
    assert_in_delta(0.07856, t.probability_equal_variance)
    assert_in_delta(0.09095, t.probability_not_equal_variance)
    
  end
  def test_t_one_sample
    u=@a.mean+(1-rand*2)
    tos=Statsample::Test::T::OneSample.new(@a,{:u=>u})
    assert_equal((@a.mean-u).quo(@a.sd.quo(Math::sqrt(@a.n))), tos.t)
    assert_equal(@a.n-1, tos.df)
    assert(tos.summary.size>0)
  end
end
