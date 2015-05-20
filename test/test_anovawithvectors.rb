require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleAnovaOneWayWithVectorsTestCase < Minitest::Test
  context(Statsample::Anova::OneWayWithVectors) do
    context('when initializing') do
      setup do
        @v1 = Daru::Vector.new(10.times.map { rand(100) })
        @v2 = Daru::Vector.new(10.times.map { rand(100) })
        @v3 = Daru::Vector.new(10.times.map { rand(100) })
      end
      should 'be the same using [] or args*' do
        a1 = Statsample::Anova::OneWayWithVectors.new(@v1, @v2, @v3)
        a2 = Statsample::Anova::OneWayWithVectors.new([@v1, @v2, @v3])
        assert_equal(a1.f, a2.f)
      end
      should 'be the same using module method or object instantiation' do
        a1 = Statsample::Anova::OneWayWithVectors.new(@v1, @v2, @v3)
        a2 = Statsample::Anova.oneway_with_vectors(@v1, @v2, @v3)
        assert_equal(a1.f, a2.f)
      end
      should 'detect optional hash' do
        a1 = Statsample::Anova::OneWayWithVectors.new(@v1, @v2, @v3, name: 'aaa')
        assert_equal('aaa', a1.name)
      end
      should 'omit incorrect arguments' do
        a1 = Statsample::Anova::OneWayWithVectors.new(@v1, @v2, @v3, name: 'aaa')
        a2 = Statsample::Anova::OneWayWithVectors.new(@v1, nil, nil, @v2, @v3, name: 'aaa')
        assert_equal(a1.f, a2.f)
      end
    end
    setup do
      @v1 = Daru::Vector.new([3, 3, 2, 3, 6])
      @v2 = Daru::Vector.new([7, 6, 5, 6, 7])
      @v3 = Daru::Vector.new([9, 8, 9, 7, 8])
      @name = 'Anova testing'
      @anova = Statsample::Anova::OneWayWithVectors.new(@v1, @v2, @v3, name: @name)
    end
    should 'store correctly contrasts' do
      c1 = Statsample::Anova::Contrast.new(vectors: [@v1, @v2, @v3], c: [1, -0.5, -0.5])

      c2 = @anova.contrast(c: [1, -0.5, -0.5])
      assert_equal(c1.t, c2.t)
    end
    should 'respond to #summary' do
      assert(@anova.respond_to? :summary)
    end
    should 'have correct name of analysis on #summary' do
      assert_match(/#{@name}/, @anova.summary)
    end
    should 'returns same levene values as direct Levene creation' do
      assert_equal(@anova.levene.f, Statsample::Test.levene([@v1, @v2, @v3]).f)
    end
    should 'have correct value for levene' do
      assert_in_delta(0.604, @anova.levene.f, 0.001)
      assert_in_delta(0.562, @anova.levene.probability, 0.001)
    end
    should 'have correct value for sst' do
      assert_in_delta(72.933, @anova.sst, 0.001)
    end
    should 'have correct value for sswg' do
      assert_in_delta(14.8, @anova.sswg, 0.001)
    end
    should 'have correct value for ssb' do
      assert_in_delta(58.133, @anova.ssbg, 0.001)
    end
    should 'sst=sswg+ssbg' do
      assert_in_delta(@anova.sst, @anova.sswg + @anova.ssbg, 0.00001)
    end
    should 'df total equal to number of n-1' do
      assert_equal(@v1.size + @v2.size + @v3.size - 1, @anova.df_total)
    end
    should 'df wg equal to number of n-k' do
      assert_equal(@v1.size + @v2.size + @v3.size - 3, @anova.df_wg)
    end
    should 'df bg equal to number of k-1' do
      assert_equal(2, @anova.df_bg)
    end
    should 'f=(ssbg/df_bg)/(sswt/df_wt)' do
      assert_in_delta((@anova.ssbg.quo(@anova.df_bg)).quo(@anova.sswg.quo(@anova.df_wg)), @anova.f, 0.001)
    end
    should 'p be correct' do
      assert(@anova.probability < 0.01)
    end
    should 'be correct using different test values' do
      anova2 = Statsample::Anova::OneWayWithVectors.new([@v1, @v1, @v1, @v1, @v2])
      assert_in_delta(3.960, anova2.f, 0.001)
      assert_in_delta(0.016, anova2.probability, 0.001)
    end
    context 'with extra information on summary' do
      setup do
        @anova.summary_descriptives = true
        @anova.summary_levene = true
        @summary = @anova.summary
      end
      should 'have section with levene statistics' do
        assert_match(/Levene/, @summary)
      end
      should 'have section with descriptives' do
        assert_match(/Min/, @summary)
      end
    end
  end
end
