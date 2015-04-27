require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleAnovaTwoWayTestCase < Minitest::Test
  context(Statsample::Anova::TwoWay) do
    setup do
      @ss_a = 192.2
      @ss_b = 57.8
      @ss_axb = 168.2
      @ss_within = 75.6
      @df_a = @df_b = 1
      @df_within = 16
      @anova = Statsample::Anova::TwoWay.new(ss_a: @ss_a, ss_b: @ss_b, ss_axb: @ss_axb, ss_within: @ss_within, df_a: @df_a, df_b: @df_b, df_within: @df_within)
    end
    should 'Statsample::Anova.twoway respond to #twoway' do
      assert(Statsample::Anova.respond_to? :twoway)
    end
    should 'return correct value for ms_a, ms_b and ms_axb' do
      assert_in_delta(192.2, @anova.ms_a, 0.01)
      assert_in_delta(57.8, @anova.ms_b, 0.01)
      assert_in_delta(168.2, @anova.ms_axb, 0.01)
    end
    should 'return correct value for f ' do
      assert_in_delta(40.68, @anova.f_a, 0.01)
      assert_in_delta(12.23, @anova.f_b, 0.01)
      assert_in_delta(35.60, @anova.f_axb, 0.01)
    end
    should 'return correct value for probability for f ' do
      assert(@anova.f_a_probability < 0.05)
      assert(@anova.f_b_probability < 0.05)
      assert(@anova.f_axb_probability < 0.05)
    end

    should 'respond to summary' do
      assert(@anova.respond_to? :summary)
      assert(@anova.summary.size > 0)
    end
  end
end
