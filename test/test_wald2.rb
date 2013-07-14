require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))

class StatsampleWaldTest < MiniTest::Unit::TestCase
  # Wald test is useful to test a series of n acf with Chi-square
  # degree of freedom. It is extremely useful to test fit the fit of
  # an ARIMA model to test the residuals.

  include Statsample::TimeSeries
  include Statsample::Shorthand
  include Distribution

  def setup
    #create time series to evaluate later
    @wald = 100.times.map { rand(100) }.to_ts
  end

  def sum_of_squares_of_acf_series(lags)
    #perform sum of squares for a series of acf with specified lags
    acf = @wald.acf(lags)
    return acf.map { |x| x ** 2 }.inject(:+)
  end

  def chisquare_cdf(sum_of_squares, lags)
    1 - ChiSquare.cdf(sum_of_squares, lags)
  end


  def test_wald_with_5_lags
    #number of lags for acf = 5
    lags = 5
    sum_of_squares = sum_of_squares_of_acf_series(lags)
    assert_in_delta chisquare_cdf(sum_of_squares, lags), 1, 0.05
    assert_equal @wald.acf(lags).size, lags + 1
  end


  def test_wald_with_10_lags
    #number of lags for acf = 10
    lags = 10
    sum_of_squares = sum_of_squares_of_acf_series(lags)
    assert_in_delta chisquare_cdf(sum_of_squares, lags), 1, 0.05
    assert_equal @wald.acf(lags).size, lags + 1
  end


  def test_wald_with_15_lags
    #number of lags for acf = 15
    lags = 15
    sum_of_squares = sum_of_squares_of_acf_series(lags)
    assert_in_delta chisquare_cdf(sum_of_squares, lags), 1, 0.05
    assert_equal @wald.acf(lags).size, lags + 1
  end


  def test_wald_with_20_lags
    #number of lags for acf = 20
    lags = 20
    sum_of_squares = sum_of_squares_of_acf_series(lags)
    assert_in_delta chisquare_cdf(sum_of_squares, lags), 1, 0.05
    assert_equal @wald.acf(lags).size, lags + 1
  end


  def test_wald_with_25_lags
    #number of lags for acf = 25
    lags = 25
    sum_of_squares = sum_of_squares_of_acf_series(lags)
    assert_in_delta chisquare_cdf(sum_of_squares, lags), 1, 0.05
    assert_equal @wald.acf(lags).size, lags + 1
  end
end
