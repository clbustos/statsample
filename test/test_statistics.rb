require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleStatisicsTestCase < Minitest::Test
  def initialize(*args)
    super
  end

  def test_p_using_cdf
    assert_equal(0.25, Statsample::Test.p_using_cdf(0.25, tails = :left))
    assert_equal(0.75, Statsample::Test.p_using_cdf(0.25, tails = :right))
    assert_equal(0.50, Statsample::Test.p_using_cdf(0.25, tails = :both))
    assert_equal(1, Statsample::Test.p_using_cdf(0.50, tails = :both))
    assert_equal(0.05, Statsample::Test.p_using_cdf(0.025, tails = :both))
    assert_in_delta(0.05, Statsample::Test.p_using_cdf(0.975, tails = :both), 0.0001)
  end

  def test_recode_repeated
    a = %w(a b c c d d d e)
    exp = %w(a b c_1 c_2 d_1 d_2 d_3 e)
    assert_equal(exp, a.recode_repeated)
  end

  def test_is_number
    assert('10'.is_number?)
    assert('-10'.is_number?)
    assert('0.1'.is_number?)
    assert('-0.1'.is_number?)
    assert('10e3'.is_number?)
    assert('10e-3'.is_number?)
    assert(!'1212-1212-1'.is_number?)
    assert(!'a10'.is_number?)
    assert(!''.is_number?)
  end

  def test_estimation_mean
    v = Daru::Vector.new([42] * 23 + [41] * 4 + [36] * 1 + [32] * 1 + [29] * 1 + [27] * 2 + [23] * 1 + [19] * 1 + [16] * 2 + [15] * 2 + [14, 11, 10, 9, 7] + [6] * 3 + [5] * 2 + [4, 3])
    assert_equal(50, v.size)
    assert_equal(1471, v.sum)
    # limits=Statsample::SRS.mean_confidence_interval_z(v.mean(), v.sds(), v.size,676,0.80)
  end

  def test_estimation_proportion
    # total
    pop = 3042
    sam = 200
    prop = 0.19
    assert_in_delta(81.8, Statsample::SRS.proportion_total_sd_ep_wor(prop, sam, pop), 0.1)

    # confidence limits
    pop = 500
    sam = 100
    prop = 0.37
    a = 0.95
    l = Statsample::SRS.proportion_confidence_interval_z(prop, sam, pop, a)
    assert_in_delta(0.28, l[0], 0.01)
    assert_in_delta(0.46, l[1], 0.01)
  end

  def test_simple_linear_regression
    a = Daru::Vector.new([1, 2, 3, 4, 5, 6])
    b = Daru::Vector.new([6, 2, 4, 10, 12, 8])
    reg = Statsample::Regression::Simple.new_from_vectors(a, b)
    assert_in_delta((reg.ssr + reg.sse).to_f, reg.sst, 0.001)
    assert_in_delta(Statsample::Bivariate.pearson(a, b), reg.r, 0.001)
    assert_in_delta(2.4, reg.a, 0.01)
    assert_in_delta(1.314, reg.b, 0.001)
    assert_in_delta(0.657, reg.r, 0.001)
    assert_in_delta(0.432, reg.r2, 0.001)
  end
end
