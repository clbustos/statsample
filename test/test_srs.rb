require File.dirname(__FILE__)+'/../lib/rubyss'
require 'test/unit'

class RubySSSrsTestCase < Test::Unit::TestCase
    def test_std_error
        assert_equal(384,RubySS::SRS.estimation_n0(0.05,0.5,0.95).to_i)
        assert_equal(108,RubySS::SRS.estimation_n(0.05,0.5,150,0.95).to_i)
        assert_in_delta(0.0289,RubySS::SRS.proportion_sd_kp_wor(0.5,100,150),0.001)
    end
end
