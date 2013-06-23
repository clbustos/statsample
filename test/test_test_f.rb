require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))
class StatsampleTestFTestCase < MiniTest::Unit::TestCase
  def setup
    @ssb=84
    @ssw=68
    @df_num=2
    @df_den=15
    @f=Statsample::Test::F.new(@ssb.quo(@df_num),@ssw.quo(@df_den), @df_num, @df_den)
    @summary=@f.summary
  end

  def test_f_value
    #should have #f equal to msb/msw
    assert_equal((@ssb.quo(@df_num)).quo(@ssw.quo(@df_den)), @f.f)
  end

  def test_df_with_num_and_den
    # df total should be equal to df_num+df_den
    assert_equal(@df_num + @df_den, @f.df_total)
  end

  def test_probability
    #should have probability near 0.002
    assert_in_delta(0.002, @f.probability, 0.0005)
  end

  def test_float_coercion
    #should be coerced into float
    assert_equal(@f.to_f, @f.f)
  end

  def test_summary_size
    assert(@summary.size>0)
  end
end
