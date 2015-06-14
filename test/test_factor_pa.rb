require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
# require 'rserve'
# require 'statsample/rserve_extension'

class StatsampleFactorTestCase < Minitest::Test
  include Statsample::Fixtures
  # Based on Hardle and Simar
  def setup
    @fixtures_dir = File.expand_path(File.dirname(__FILE__) + '/fixtures')
    Daru.lazy_update = true
  end

  def teardown
    Daru.lazy_update = false
  end

  def test_parallelanalysis_with_data
    if Statsample.has_gsl?
      samples = 100
      variables = 10
      iterations = 50
      rng = Distribution::Normal.rng
      f1 = Daru::Vector.new(samples.times.collect { rng.call })
      f2 = Daru::Vector.new(samples.times.collect { rng.call })
      vectors = {}
      variables.times do |i|
        if i < 5
          vectors["v#{i}".to_sym] = Daru::Vector.new(          
            samples.times.collect { |nv|
              f1[nv] * 5 + f2[nv] * 2 + rng.call
            }
          )
        else
          vectors["v#{i}".to_sym] =  Daru::Vector.new(
            samples.times.collect { |nv|
              f2[nv] * 5 + f1[nv] * 2 + rng.call
            }
          )
        end
      end
      ds = Daru::DataFrame.new(vectors)

      pa1 = Statsample::Factor::ParallelAnalysis.new(ds, bootstrap_method: :data, iterations: iterations)
      pa2 = Statsample::Factor::ParallelAnalysis.with_random_data(samples, variables, iterations: iterations, percentil: 95)
      3.times do |n|
        var = "ev_0000#{n + 1}".to_sym
        assert_in_delta(pa1.ds_eigenvalues[var].mean, pa2.ds_eigenvalues[var].mean, 0.05)
      end
    else
      skip('Too slow without GSL')
    end
  end

  def test_parallelanalysis
    pa = Statsample::Factor::ParallelAnalysis.with_random_data(305, 8, iterations: 100, percentil: 95)
    assert_in_delta(1.2454, pa.ds_eigenvalues[:ev_00001].mean, 0.01)
    assert_in_delta(1.1542, pa.ds_eigenvalues[:ev_00002].mean, 0.01)
    assert_in_delta(1.0836, pa.ds_eigenvalues[:ev_00003].mean, 0.01)
    assert(pa.summary.size > 0)
  end
end
