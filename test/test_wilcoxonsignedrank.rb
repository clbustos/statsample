require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleUMannWhitneyTestCase < Minitest::Test
  include Statsample::Test
  context Statsample::Test::WilcoxonSignedRank do
    context 'Example 1' do
      setup do
        @v1 = Daru::Vector.new([110, 122, 125, 120, 140, 124, 123, 137, 135, 145])
        @v2 = Daru::Vector.new([125, 115, 130, 140, 140, 115, 140, 125, 140, 135])
        @u = Statsample::Test::WilcoxonSignedRank.new(@v1, @v2)
      end
      should 'have same result using class or Test#u_mannwhitney' do
        assert_equal(Statsample::Test.wilcoxon_signed_rank(@v1, @v2).w, @u.w)
      end
      should 'have correct W values' do
        assert_equal(9, @u.w)
      end
      should 'have correct nr values' do
        assert_equal(9, @u.nr)
      end
      should 'have correct value for z' do
        assert_in_delta(0.503, @u.z, 0.001)
      end
      should 'have correct value for probability_z' do
        assert_in_delta(0.614, @u.probability_z, 0.001)
      end
      should 'have correct value for probability_exact' do
        assert_in_delta(0.652, @u.probability_exact, 0.001)
      end
      should 'have summary' do
        assert(@u.summary != '')
      end
    end

    context 'Example 2' do
      setup do
        @v2 = Daru::Vector.new([78, 24, 64, 45, 64, 52, 30, 50, 64, 50, 78, 22, 84, 40, 90, 72])
        @v1 = Daru::Vector.new([78, 24, 62, 48, 68, 56, 25, 44, 56, 40, 68, 36, 68, 20, 58, 32])
        @u = Statsample::Test::WilcoxonSignedRank.new(@v1, @v2)
      end
      should 'have same result using class or Test#u_mannwhitney' do
        assert_equal(Statsample::Test.wilcoxon_signed_rank(@v1, @v2).w, @u.w)
      end
      should 'have correct W values' do
        assert_equal(67, @u.w)
      end
      should 'have correct nr values' do
        assert_equal(14, @u.nr)
      end
      should 'have correct value for z' do
        assert_in_delta(2.087, @u.z, 0.001)
      end
      should 'have correct value for probability_z' do
        assert_in_delta(0.036, @u.probability_z, 0.001)
      end
      should 'have correct value for probability_exact' do
        assert_in_delta(0.036, @u.probability_exact, 0.001)
      end
      should 'have summary' do
        assert(@u.summary != '')
      end
    end
  end
end
