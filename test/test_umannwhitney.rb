$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'test/unit'

class StatsampleSrsTestCase < Test::Unit::TestCase
    def test_u_mannwhitney
      v1=[1,2,3,4,7,8,9,10,14,15].to_scale
      v2=[5,6,11,12,13,16,17,18,19].to_scale
      u=Statsample::Test::UMannWhitney.new(v1,v2)
      assert_equal(73,u.r1)
      assert_equal(117,u.r2)
      assert_equal(18,u.u)
      assert_in_delta(-2.205,u.z,0.001)
      assert_in_delta(0.027,u.z_probability,0.001)
      assert_in_delta(0.028,u.exact_probability,0.001)
    end
end
