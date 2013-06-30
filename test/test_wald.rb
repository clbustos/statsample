require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))

class StatsampleTestWaldTest < MiniTest::Unit::TestCase
  include Statsample::Shorthand
  include Statsample::TimeSeries
  def setup
    @wald = 100.times.map do
      rand(100)
    end.to_ts
  end

  def generate_acf_series(lags)
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
    assert_equal (generate_acf_series(5)/5).to_i, compute_chi_df(5)
    assert_equal generate_acf_series(5), @wald.acf(5).map { |x| x ** 2 }.inject(:+)
  end

  def test_with_10_lags
    assert_equal (generate_acf_series(5)/5).to_i, compute_chi_df(5)
  end

  def test_with_15_lags
    assert_equal (generate_acf_series(5)/5).to_i, compute_chi_df(5)
  end

  def test_with_20_lags
    assert_equal (generate_acf_series(5)/5).to_i, compute_chi_df(5)
  end

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

