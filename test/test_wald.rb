require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))

class StatsampleTestWaldTest < MiniTest::Unit::TestCase

  # Wald 
  include Statsample::Shorthand
  include Statsample::TimeSeries
  def setup
    @wald = 100.times.map do
      rand(100)
    end.to_ts
  end

  def generate_acf_series(lags)
    @wald.acf(lags)
  end

  def compute_mean(acf)
    acf.inject(:+) / acf.size
  end

  def compute_variance(acf)
    result = acf.map { |x| x ** 2 }.inject(:+) / acf.size
    return result.to_f
  end

  def generate_acf_summation(lags)
    acf_series = @wald.acf(lags)
    acf_series.map do |x|
      x ** 2
    end.inject(:+)
  end

  def compute_chi_df(lags)
    observed = Matrix[@wald.acf(lags)]
    Statsample::Test.chi_square(observed).df
  end

  def test_with_5_lags
    acf = generate_acf_series(5)
    assert_equal generate_acf_summation(5), @wald.acf(5).map { |x| x ** 2 }.inject(:+)
    assert_in_delta compute_mean(acf).to_i, 0
    assert_in_delta compute_variance(acf), 1.0/acf.size, 0.1
    assert_equal (generate_acf_summation(5)/5).to_i, compute_chi_df(5)

  end

  def test_with_10_lags
    acf = generate_acf_series(10)
    assert_equal generate_acf_summation(10), @wald.acf(10).map { |x| x ** 2 }.inject(:+)
    assert_in_delta compute_mean(acf).to_i, 0
    assert_in_delta compute_variance(acf), 1.0/acf.size, 0.1
    assert_equal (generate_acf_summation(10)/10).to_i, compute_chi_df(10)
  end

  def test_with_15_lags
    acf = generate_acf_series(15)
    assert_equal generate_acf_summation(15), @wald.acf(15).map { |x| x ** 2 }.inject(:+)
    assert_in_delta compute_mean(acf).to_i, 0
    assert_in_delta compute_variance(acf), 1.0/acf.size, 0.1
    assert_equal (generate_acf_summation(15)/15).to_i, compute_chi_df(15)
  end

  def test_with_20_lags
    acf = generate_acf_series(20)
    assert_equal generate_acf_summation(20), @wald.acf(20).map { |x| x ** 2 }.inject(:+)
    assert_in_delta compute_mean(acf).to_i, 0
    assert_in_delta compute_variance(acf), 1.0/acf.size, 0.1
    assert_equal (generate_acf_summation(20)/20).to_i, compute_chi_df(20)
  end
  # DELETE THIS TEST
  def test_with_different_series
    @wald = 200.times.map { rand }.to_ts
    acf_series = @wald.acf(10)
    lhs = acf_series.each { |x| x ** 2 }.inject(:+)
    
    rhs = Statsample::Test.chi_square(Matrix[acf_series]).df
    assert_equal (lhs/10).to_i, rhs
  end

  def test_pacf
    #TODO
  end
end

