require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleTestFTestCase < Minitest::Test
  context(Statsample::Test::F) do
    setup do
      @ssb = 84
      @ssw = 68
      @df_num = 2
      @df_den = 15
      @f = Statsample::Test::F.new(@ssb.quo(@df_num), @ssw.quo(@df_den), @df_num, @df_den)
    end
    should 'have #f equal to msb/msw' do
      assert_equal((@ssb.quo(@df_num)).quo(@ssw.quo(@df_den)), @f.f)
    end
    should 'have df total equal to df_num+df_den' do
      assert_equal(@df_num + @df_den, @f.df_total)
    end
    should 'have probability near 0.002' do
      assert_in_delta(0.002, @f.probability, 0.0005)
    end
    should 'be coerced into float' do
      assert_equal(@f.to_f, @f.f)
    end

    context('method summary') do
      setup do
        @summary = @f.summary
      end
      should 'have size > 0' do
        assert(@summary.size > 0)
      end
    end
  end
end
