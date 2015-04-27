require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleTestKolmogorovSmirnovTestCase < Minitest::Test
  context(Statsample::Test::KolmogorovSmirnov) do
    should 'calculate correctly D for two given samples' do
      a = [1.1, 2.5, 5.6, 9]
      b = [1, 2.3, 5.8, 10]
      ks = Statsample::Test::KolmogorovSmirnov.new(a, b)
      assert_equal(0.25, ks.d)
    end
    should 'calculate correctly D for a normal sample and Normal Distribution' do
      a = [0.30022510, -0.36664035, 0.08593404, 1.29881130, -0.49878633, -0.63056010, 0.28397638, -0.04913700, 0.03566644, -1.33414346]
      ks = Statsample::Test::KolmogorovSmirnov.new(a, Distribution::Normal)
      assert_in_delta(0.282, ks.d, 0.001)
    end
    should 'calculate correctly D for a variable normal and Normal Distribution' do
      rng = Distribution::Normal.rng
      a = 100.times.map { rng.call }
      ks = Statsample::Test::KolmogorovSmirnov.new(a, Distribution::Normal)
      assert(ks.d < 0.15)
    end

    context(Statsample::Test::KolmogorovSmirnov::EmpiricDistribution) do
      should 'Create a correct empirical distribution for an array' do
        a = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
        ed = Statsample::Test::KolmogorovSmirnov::EmpiricDistribution.new(a)
        assert_equal(0, ed.cdf(-2))
        assert_equal(0.5, ed.cdf(5))
        assert_equal(0.5, ed.cdf(5.5))
        assert_equal(0.9, ed.cdf(9))
        assert_equal(1, ed.cdf(11))
      end
    end
  end
end
