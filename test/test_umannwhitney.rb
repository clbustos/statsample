require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleUMannWhitneyTestCase < Minitest::Test
  include Statsample::Test
  context Statsample::Test::UMannWhitney do
    setup do
      @v1 = Daru::Vector.new([1, 2, 3, 4, 7, 8, 9, 10, 14, 15])
      @v2 = Daru::Vector.new([5, 6, 11, 12, 13, 16, 17, 18, 19])
      @u = Statsample::Test::UMannWhitney.new(@v1, @v2)
    end
    should 'have same result using class or Test#u_mannwhitney' do
      assert_equal(Statsample::Test.u_mannwhitney(@v1, @v2).u, @u.u)
    end
    should 'have correct U values' do
      assert_equal(73, @u.r1)
      assert_equal(117, @u.r2)
      assert_equal(18, @u.u)
    end
    should 'have correct value for z' do
      assert_in_delta(-2.205, @u.z, 0.001)
    end
    should 'have correct value for z and exact probability' do
      assert_in_delta(0.027, @u.probability_z, 0.001)
      assert_in_delta(0.028, @u.probability_exact, 0.001)
    end
  end
end
