require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))

class StatsampleSrsTestCase < MiniTest::Unit::TestCase
  def test_std_error
    assert_equal(384,Statsample::SRS.estimation_n0(0.05,0.5,0.95).to_i)
    assert_equal(108,Statsample::SRS.estimation_n(0.05,0.5,150,0.95).to_i)
    assert_in_delta(0.0289,Statsample::SRS.proportion_sd_kp_wor(0.5,100,150),0.001)
  end

  def test_fpc
    sample_size = 80
    population_size = 10

    assert_equal -7, Statsample::SRS.fpc_var(sample_size, population_size).to_i
  end

  def test_qf
    sample_size = 80
    population_size = 10

    assert_equal -7, Statsample::SRS.qf(sample_size, population_size).to_i
    #non sample fraction = 1 - sample fraction
    assert_equal -7, 1 - sample_size.quo(population_size)
  end

  def test_proportion_confidence_interval_t
    proportion = 59
    n_sample, n_population = 15, 10
    confidence_interval = Statsample::SRS.proportion_confidence_interval_t(proportion, n_sample, n_population).map(&:to_f)

    assert_in_delta 35.2559, confidence_interval[0], 0.001
    assert_in_delta 82.7440, confidence_interval[1], 0.001
  end

  def test_proportion_confidence_interval_z
    #estimated proportion with normal distribution.
    proportion = 59
    n_sample, n_population = 15, 10
    confidence_interval = Statsample::SRS.proportion_confidence_interval_z(proportion, n_sample, n_population).map(&:to_f)

    assert_in_delta 37.2991, confidence_interval[0], 0.001
    assert_in_delta 80.7008, confidence_interval[1], 0.001
  end

  def test_proportion_sd_kp_wor
    #standard deviation without replacement strategy for known proportion
    assert_in_delta 11.6979, Statsample::SRS.proportion_sd_kp_wor(40, -30, 20), 0.001
  end

  def test_proportion_sd_ep_wor
    #standard deviation with replacement for estimated proportion
    assert_in_delta 35.5527, Statsample::SRS.proportion_sd_ep_wr(80, -4), 0.001
    assert_in_delta 38.9700, Statsample::SRS.proportion_sd_ep_wr(68, -2), 0.001
  end
end
