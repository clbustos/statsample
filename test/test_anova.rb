$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'test/unit'

class StatsampleAnovaTestCase < Test::Unit::TestCase
	def initialize(*args)
        @v1=[3,3,2,3,6].to_vector(:scale)
        @v2=[7,6,5,6,7].to_vector(:scale)
        @v3=[9,8,9,7,8].to_vector(:scale)
        @anova=Statsample::Anova::OneWay.new([@v1,@v2,@v3])
		super
	end
    def test_basic
        assert_in_delta(72.933, @anova.sst,0.001)
        assert_in_delta(14.8,@anova.sswg,0.001)
        assert_in_delta(58.133,@anova.ssbg,0.001)
        assert_in_delta(@anova.sst,@anova.sswg+@anova.ssbg,0.00001)
        assert_equal(14,@anova.df_total)
        assert_equal(12,@anova.df_wg)
        assert_equal(2,@anova.df_bg)
        assert_in_delta(23.568,@anova.f,0.001)
        anova2=Statsample::Anova::OneWay.new([@v1,@v1,@v1,@v1,@v2])
        assert_in_delta(3.960, anova2.f,0.001)
		assert(@anova.significance<0.01)
		assert_in_delta(0.016, anova2.significance,0.001)
    end
end