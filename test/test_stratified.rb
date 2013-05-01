require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))

class StatsampleStratifiedTestCase < MiniTest::Unit::TestCase

  def initialize(*args)
    @es = [
      {"N" => 5, "s" => 3, "n" => 2},
      {"N" => 10, "s" => 5, "n" => 2},
      {"N" => 30, "s" => 32, "n" => 12}
    ]
    super
  end
  def test_mean
    a=[10,20,30,40,50]
    b=[110,120,130,140]
    pop=a+b
    av=a.to_vector(:scale)
    bv=b.to_vector(:scale)
    popv=pop.to_vector(:scale)
    assert_equal(popv.mean,Statsample::StratifiedSample.mean(av,bv))
  end

  def test_standard_error_ksd_wr
    # Standard error for known sample design with replacement
    es = [
      {"N" => 5, "s" => 3, "n" => 2},
      {"N" => 10, "s" => 5, "n" => 2},
      {"N" => 30, "s" => 32, "n" => 12}
    ]
    assert_in_delta 6.21279, Statsample::StratifiedSample.standard_error_ksd_wr(es), 0.001
  end

  def test_variance_ksd_wr
    # variance of known sample desgin with replacement
    result = Statsample::StratifiedSample.variance_ksd_wr(@es)

    assert_in_delta 38.5987, result, 0.001
    assert_in_delta Statsample::StratifiedSample.standard_error_ksd_wr(@es), Math::sqrt(result), 0.001
  end

  def test_calculate_n_total
    # calculates total 'n' from the hash

    assert_equal 45, Statsample::StratifiedSample.calculate_n_total(@es)
    assert_equal 15, Statsample::StratifiedSample.calculate_n_total(@es.first(2))
    assert_equal 40, Statsample::StratifiedSample.calculate_n_total(@es.last(2))
  end

  def test_variance_ksd_wor
    # variance of known sample desgin without replacement

    assert_in_delta 23.2827, Statsample::StratifiedSample.variance_ksd_wor(@es), 0.001
    assert_in_delta 4.7444, Statsample::StratifiedSample.variance_ksd_wor(@es.first(2)), 0.001
  end

  def test_standard_error_ksd_wor
    # standard error for known sample design without replacement
    #
    assert_in_delta 4.8252, Statsample::StratifiedSample.standard_error_ksd_wor(@es), 0.001

    #for fragment sample design
    assert_in_delta 5.4244, Statsample::StratifiedSample.standard_error_ksd_wor(@es.last 2), 0.001
  end

  def test_variance_esd_wor
    # variance of estimated sample design without replacement strategry
    assert_in_delta 23.2827, Statsample::StratifiedSample.variance_esd_wor(@es), 0.001
  end

  def test_standard_error_esd_wor
    # Standard error for estimated sample design without replacement
    assert_in_delta 4.82521, Statsample::StratifiedSample.standard_error_esd_wor(@es), 0.001
  end

  def test_standard_error_esd_wr
    res = Statsample::StratifiedSample.standard_error_esd_wr(@es)
    assert_in_delta 6.21279, res, 0.001
    assert_in_delta Statsample::StratifiedSample.variance_esd_wr(@es), res ** 2, 0.001
  end

  def test_variance_esd_wr
    # variance for estimated sample dsign with replacement

    assert_in_delta 38.5987, Statsample::StratifiedSample.variance_esd_wr(@es), 0.001
  end

end
