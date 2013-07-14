require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))

class StatsampleTestTimeSeries < MiniTest::Unit::TestCase
  include Statsample::Shorthand

  # All calculations are compared to the output of the equivalent function in R

  def setup
    # daily closes of iShares XIU on the TSX
    @xiu = Statsample::TimeSeries::TimeSeries.new [17.28, 17.45, 17.84, 17.74, 17.82, 17.85, 17.36, 17.3, 17.56, 17.49, 17.46, 17.4, 17.03, 17.01,
      16.86, 16.86, 16.56, 16.36, 16.66, 16.77], :scale
  end

  def test_acf
    acf = @xiu.acf

    assert_equal 14,       acf.length

    # test the first few autocorrelations
    assert_in_delta 1.0,   acf[0], 0.0001
    assert_in_delta 0.852, acf[1], 0.001
    assert_in_delta 0.669, acf[2], 0.001
    assert_in_delta 0.486, acf[3], 0.001
  end

  def test_lag
    #test of default lag
    lag1 = @xiu.lag

    assert_in_delta 16.66, lag1[lag1.size - 1], 0.001
    assert_in_delta 16.36, lag1[lag1.size - 2], 0.001

    #test with different lagging unit
    lag2 = @xiu.lag(2)

    assert_in_delta 16.36, lag2[lag2.size - 1], 0.001
    assert_in_delta 16.56, lag2[lag2.size - 2], 0.001
  end

  def test_delta
    diff = @xiu.diff

    assert_in_delta  0.11, diff[@xiu.size - 1], 0.001
    assert_in_delta  0.30, diff[@xiu.size - 2], 0.001
    assert_in_delta -0.20, diff[@xiu.size - 3], 0.001
  end

  def test_ma
    # test default
    ma10 = @xiu.ma

    assert_in_delta ma10[-1],  16.897, 0.001
    assert_in_delta ma10[-5],  17.233, 0.001
    assert_in_delta ma10[-10], 17.587, 0.001

    # test with a different lookback period
    ma5 = @xiu.ma 5

    assert_in_delta ma5[-1],  16.642, 0.001
    assert_in_delta ma5[-10], 17.434, 0.001
    assert_in_delta ma5[-15], 17.74,  0.001
  end

  def test_ema
    # test default
    ema10 = @xiu.ema

    assert_in_delta ema10[-1],  16.87187, 0.00001
    assert_in_delta ema10[-5],  17.19187, 0.00001
    assert_in_delta ema10[-10], 17.54918, 0.00001

    # test with a different lookback period
    ema5 = @xiu.ema 5

    assert_in_delta ema5[-1],  16.71299, 0.0001
    assert_in_delta ema5[-10], 17.49079, 0.0001
    assert_in_delta ema5[-15], 17.70067, 0.0001

    # test with a different smoother
    ema_w = @xiu.ema 10, true

    assert_in_delta ema_w[-1],  17.08044, 0.00001
    assert_in_delta ema_w[-5],  17.33219, 0.00001
    assert_in_delta ema_w[-10], 17.55810, 0.00001
  end

  def test_macd
    # MACD uses a lot more data than the other ones, so we need a bigger vector
    data = File.readlines(File.dirname(__FILE__) + "/fixtures/stock_data.csv").map(&:to_f).to_time_series

    macd, signal = data.macd

    # check the MACD
    assert_in_delta  3.12e-4, macd[-1],  1e-6
    assert_in_delta -1.07e-2, macd[-10], 1e-4
    assert_in_delta -5.65e-3, macd[-20], 1e-5

    # check the signal
    assert_in_delta -0.00628, signal[-1],  1e-5
    assert_in_delta -0.00971, signal[-10], 1e-5
    assert_in_delta -0.00338, signal[-20], 1e-5
  end
end
