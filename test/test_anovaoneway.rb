require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleAnovaOneWayTestCase < Minitest::Test
  context(Statsample::Anova::OneWay) do
    setup do
      @ss_num = 30.08
      @ss_den = 87.88
      @df_num = 2
      @df_den = 21
      @anova = Statsample::Anova::OneWay.new(ss_num: @ss_num, ss_den: @ss_den, df_num: @df_num, df_den: @df_den)
    end
    should 'Statsample::Anova.oneway respond to #oneway' do
      assert(Statsample::Anova.respond_to? :oneway)
    end
    should 'return correct value for ms_num and ms_den' do
      assert_in_delta(15.04, @anova.ms_num, 0.01)
      assert_in_delta(4.18, @anova.ms_den, 0.01)
    end
    should 'return correct value for f' do
      assert_in_delta(3.59, @anova.f, 0.01)
    end
    should 'respond to summary' do
      assert(@anova.respond_to? :summary)
      assert(@anova.summary.size > 0)
    end
  end
end
