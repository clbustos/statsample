require(File.dirname(__FILE__)+'/test_helpers.rb')

class StatsampleTestFTestCase < MiniTest::Unit::TestCase
  context(Statsample::Test::F) do 
    setup do
      @ssb=84
      @ssw=68
      @f=Statsample::Test::F.new(@ssb,@ssw, 2,15)
    end
    should "have f equal to msb/msw" do
      assert_equal((@ssb.quo(2)).quo(@ssw.quo(15)), @f.f)
    end
    should "have df total equal to df_num+df_den" do
      assert_equal(17, @f.df_total)
    end
    should "have probability near 0.002" do 
      assert_in_delta(0.002, @f.probability, 0.0005)
    end
    context("#summary") do
      setup do
        @f.name_numerator="MSb"
        @f.name_denominator="MSw"
        @f.name="ANOVA"
        @summary=@f.summary
      end
      should "have size > 0" do
        assert(@summary.size>0)
      end
      should "include correct names for title, num and den" do
        assert_match(@f.name_numerator, @summary)
        assert_match(@f.name_denominator, @summary)
        assert_match(@f.name, @summary)
      end
    end
  end

end
