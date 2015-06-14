require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
# Reference:
# * http://www.uwsp.edu/psych/Stat/13/anova-2w.htm#III
class StatsampleAnovaTwoWayWithVectorsTestCase < Minitest::Test
  context(Statsample::Anova::TwoWayWithVectors) do
    setup do
      @pa = Daru::Vector.new [5, 4, 3, 4, 2, 18, 19, 14, 12, 15, 6, 7, 5, 8, 4, 6, 9, 5, 9, 3]
      @pa.rename 'Passive Avoidance'
      @a = Daru::Vector.new [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1]
      # @a.labels = { 0 => '0%', 1 => '35%' }
      @a.rename 'Diet'
      @b = Daru::Vector.new [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
      # @b.labels = { 0 => 'Young', 1 => 'Older' }
      @b.rename 'Age'
      @anova = Statsample::Anova::TwoWayWithVectors.new(a: @a, b: @b, dependent: @pa)
    end
    should 'Statsample::Anova respond to #twoway_with_vectors' do
      assert(Statsample::Anova.respond_to? :twoway_with_vectors)
    end
    should '#new returns the same as Statsample::Anova.twoway_with_vectors' do
      @anova2 = Statsample::Anova.twoway_with_vectors(a: @a, b: @b, dependent: @pa)
      assert_equal(@anova.summary, @anova2.summary)
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
      @anova.summary_descriptives = true
      @anova.summary_levene = true
      assert(@anova.respond_to? :summary)
      assert(@anova.summary.size > 0)
    end
  end
end
