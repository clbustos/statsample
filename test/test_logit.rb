require(File.dirname(__FILE__)+'/helpers_tests.rb')

class StatsampleLogitTestCase < MiniTest::Unit::TestCase
  def test_logit_1
    crime=File.dirname(__FILE__)+'/../data/test_binomial.csv'
    ds=Statsample::CSV.read(crime)
    lr=Statsample::Regression::Binomial::Logit.new(ds,'y')
    assert_in_delta(-38.8669,lr.log_likehood,0.001)
    assert_in_delta(-5.3658,lr.constant,0.001)

    exp_coeffs={"a"=>0.3270,"b"=>0.8147, "c"=>-0.4031}
    exp_coeffs.each{|k,v|
      assert_in_delta(v,lr.coeffs[k],0.001)
    }
    exp_errors={'a'=>0.4390,'b'=>0.4270,'c'=>0.3819}
    exp_errors.each{|k,v|
      assert_in_delta(v,lr.coeffs_se[k],0.001)
    }
    assert_equal(7,lr.iterations)
  end
end
