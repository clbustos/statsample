require(File.dirname(__FILE__)+'/test_helpers.rb')

class StatsampleBivariatePolychoricTestCase < MiniTest::Unit::TestCase
  context Statsample::Bivariate::Polychoric do
    setup do
      matrix=Matrix[[58,52,1],[26,58,3],[8,12,9]]
      @poly=Statsample::Bivariate::Polychoric.new(matrix)
    end
    should "have summary.size > 0" do
      assert(@poly.summary.size>0)
    end
    should "compute two step mle with ruby" do
      @poly.compute_two_step_mle_drasgow_ruby
      assert_in_delta(0.420, @poly.r, 0.001)
      assert_in_delta(-0.240, @poly.threshold_y[0],0.001)
      assert_in_delta(-0.027, @poly.threshold_x[0],0.001)
      assert_in_delta(1.578, @poly.threshold_y[1],0.001)
      assert_in_delta(1.137, @poly.threshold_x[1],0.001)
    end
    should "compute two-step with gsl" do
      if Statsample.has_gsl?
        @poly.compute_two_step_mle_drasgow_gsl
        assert_in_delta(0.420, @poly.r, 0.001)
        assert_in_delta(-0.240, @poly.threshold_y[0],0.001)
        assert_in_delta(-0.027, @poly.threshold_x[0],0.001)
        assert_in_delta(1.578, @poly.threshold_y[1],0.001)
        assert_in_delta(1.137, @poly.threshold_x[1],0.001)
      else
        skip "Requires GSL"
      end
    end
    should "compute polychoric series" do 
      if Statsample.has_gsl?
      @poly.method=:polychoric_series
      @poly.compute
      assert_in_delta(0.556, @poly.r, 0.001)
      assert_in_delta(-0.240, @poly.threshold_y[0],0.001)
      assert_in_delta(-0.027, @poly.threshold_x[0],0.001)
      assert_in_delta(1.578, @poly.threshold_y[1],0.001)
      assert_in_delta(1.137, @poly.threshold_x[1],0.001)
      end
    end
  should "compute joint" do
    if Statsample.has_gsl?
      @poly.method=:joint
      @poly.compute
      assert_in_delta(0.4192, @poly.r, 0.0001)
      assert_in_delta(-0.2421, @poly.threshold_y[0],0.0001)
      assert_in_delta(-0.0297, @poly.threshold_x[0],0.0001)
      assert_in_delta(1.5938, @poly.threshold_y[1],0.0001)
      assert_in_delta(1.1331, @poly.threshold_x[1],0.0001)
    end
  end  
  end
  
end
