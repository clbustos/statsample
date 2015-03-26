require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleSrsTestCase < Minitest::Test
  def test_std_error
    assert_equal(384, Statsample::SRS.estimation_n0(0.05, 0.5, 0.95).to_i)
    assert_equal(108, Statsample::SRS.estimation_n(0.05, 0.5, 150, 0.95).to_i)
    assert_in_delta(0.0289, Statsample::SRS.proportion_sd_kp_wor(0.5, 100, 150), 0.001)
  end
end
