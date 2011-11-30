require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))

class StatsampleTestTimeSeries < MiniTest::Unit::TestCase
  include Statsample::Shorthand

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
    assert_in_delta 16.66, @xiu.lag[@xiu.size - 1], 0.001
    assert_in_delta 16.36, @xiu.lag(2)[@xiu.size - 1], 0.001
  end

  def test_delta
    diff = @xiu.diff

    assert_in_delta  0.11, diff[@xiu.size - 1], 0.001
    assert_in_delta  0.30, diff[@xiu.size - 2], 0.001
    assert_in_delta -0.20, diff[@xiu.size - 3], 0.001
  end
end
