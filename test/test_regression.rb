require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleRegressionTestCase < Minitest::Test
  context 'Example with missing data' do
    setup do
      @x = Daru::Vector.new([0.285714285714286, 0.114285714285714, 0.314285714285714, 0.2, 0.2, 0.228571428571429, 0.2, 0.4, 0.714285714285714, 0.285714285714286, 0.285714285714286, 0.228571428571429, 0.485714285714286, 0.457142857142857, 0.257142857142857, 0.228571428571429, 0.285714285714286, 0.285714285714286, 0.285714285714286, 0.142857142857143, 0.285714285714286, 0.514285714285714, 0.485714285714286, 0.228571428571429, 0.285714285714286, 0.342857142857143, 0.285714285714286, 0.0857142857142857])

      @y = Daru::Vector.new([nil, 0.233333333333333, nil, 0.266666666666667, 0.366666666666667, nil, 0.333333333333333, 0.3, 0.666666666666667, 0.0333333333333333, 0.333333333333333, nil, nil, 0.533333333333333, 0.433333333333333, 0.4, 0.4, 0.5, 0.4, 0.266666666666667, 0.166666666666667, 0.666666666666667, 0.433333333333333, 0.166666666666667, nil, 0.4, 0.366666666666667, nil])
      @ds = Daru::DataFrame.new({ :x => @x, :y => @y })
      @lr = Statsample::Regression::Multiple::RubyEngine.new(@ds, :y)
    end
    should 'have correct values' do
      assert_in_delta(0.455, @lr.r2, 0.001)
      assert_in_delta(0.427, @lr.r2_adjusted, 0.001)
      assert_in_delta(0.1165, @lr.se_estimate, 0.001)
      assert_in_delta(15.925, @lr.f, 0.0001)
      assert_in_delta(0.675, @lr.standarized_coeffs[:x], 0.001)
      assert_in_delta(0.778, @lr.coeffs[:x], 0.001, 'coeff x')
      assert_in_delta(0.132, @lr.constant, 0.001, 'constant')
      assert_in_delta(0.195, @lr.coeffs_se[:x], 0.001, 'coeff x se')
      assert_in_delta(0.064, @lr.constant_se, 0.001, 'constant se')
    end
  end
  should 'return an error if data is linearly dependent' do
    samples = 100

    a, b = rand, rand

    x1 = Daru::Vector.new(samples.times.map { rand })
    x2 = Daru::Vector.new(samples.times.map { rand })
    x3 = Daru::Vector.new(samples.times.map { |i| x1[i] * (1 + a) + x2[i] * (1 + b) })
    y  = Daru::Vector.new(samples.times.map { |i| x1[i] + x2[i] + x3[i] + rand })

    ds = Daru::DataFrame.new({ :x1 => x1, :x2 => x2, :x3 => x3, :y => y })

    assert_raise(Statsample::Regression::LinearDependency) {
      Statsample::Regression::Multiple::RubyEngine.new(ds, :y)
    }
  end
  def test_parameters
    @x =Daru::Vector.new([13, 20, 10, 33, 15])
    @y =Daru::Vector.new([23, 18, 35, 10, 27])
    reg = Statsample::Regression::Simple.new_from_vectors(@x, @y)
    _test_simple_regression(reg)
    ds = Daru::DataFrame.new({ :x => @x, :y => @y })
    reg = Statsample::Regression::Simple.new_from_dataset(ds, :x, :y)
    _test_simple_regression(reg)
    reg = Statsample::Regression.simple(@x, @y)
    _test_simple_regression(reg)
  end

  def _test_simple_regression(reg)
    assert_in_delta(40.009, reg.a, 0.001)
    assert_in_delta(-0.957, reg.b, 0.001)
    assert_in_delta(4.248, reg.standard_error, 0.002)
    assert(reg.summary)
  end

  def test_summaries
    a = Daru::Vector.new(10.times.map { rand(100) })
    b = Daru::Vector.new(10.times.map { rand(100) })
    y = Daru::Vector.new(10.times.map { rand(100) })
    ds = Daru::DataFrame.new({ :a => a, :b => b, :y => y })
    lr = Statsample::Regression::Multiple::RubyEngine.new(ds, :y)
    assert(lr.summary.size > 0)
  end

  def test_multiple_dependent
    complete = Matrix[
      [1, 0.53, 0.62, 0.19, -0.09, 0.08, 0.02, -0.12, 0.08],
      [0.53, 1, 0.61, 0.23, 0.1, 0.18, 0.02, -0.1, 0.15],
      [0.62, 0.61, 1, 0.03, 0.1, 0.12, 0.03, -0.06, 0.12],
      [0.19, 0.23, 0.03, 1, -0.02, 0.02, 0, -0.02, -0.02],
      [-0.09, 0.1, 0.1, -0.02, 1, 0.05, 0.06, 0.18, 0.02],
      [0.08, 0.18, 0.12, 0.02, 0.05, 1, 0.22, -0.07, 0.36],
      [0.02, 0.02, 0.03, 0, 0.06, 0.22, 1, -0.01, -0.05],
      [-0.12, -0.1, -0.06, -0.02, 0.18, -0.07, -0.01, 1, -0.03],
      [0.08, 0.15, 0.12, -0.02, 0.02, 0.36, -0.05, -0.03, 1]]
    complete.extend Statsample::CovariateMatrix
    complete.fields = %w(adhd cd odd sex age monly mwork mage poverty)

    lr = Statsample::Regression::Multiple::MultipleDependent.new(complete, %w(adhd cd odd))

    assert_in_delta(0.197, lr.r2yx, 0.001)
    assert_in_delta(0.197, lr.r2yx_covariance, 0.001)
    assert_in_delta(0.07, lr.p2yx, 0.001)
  end

  def test_multiple_regression_pairwise_2
    @a =Daru::Vector.new( [1, 3, 2, 4, 3, 5, 4, 6, 5, 7, 3, nil, 3, nil, 3])
    @b =Daru::Vector.new( [3, 3, 4, 4, 5, 5, 6, 6, 4, 4, 2, 2, nil, 6, 2])
    @c =Daru::Vector.new( [11, 22, 30, 40, 50, 65, 78, 79, 99, 100, nil, 3, 7, nil, 7])
    @y =Daru::Vector.new( [3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 30, 40, nil, 50, nil])
    ds = Daru::DataFrame.new({ :a => @a, :b => @b, :c => @c, :y => @y })
    lr = Statsample::Regression::Multiple::RubyEngine.new(ds, :y)
    assert_in_delta(2407.436, lr.sst, 0.001)
    assert_in_delta(0.752, lr.r, 0.001, 'pairwise r')
    assert_in_delta(0.565, lr.r2, 0.001)
    assert_in_delta(1361.130, lr.ssr, 0.001)
    assert_in_delta(1046.306, lr.sse, 0.001)
    assert_in_delta(3.035, lr.f, 0.001)
  end

  def test_multiple_regression_gsl
    if Statsample.has_gsl?
      @a =Daru::Vector.new( [1, 3, 2, 4, 3, 5, 4, 6, 5, 7])
      @b =Daru::Vector.new( [3, 3, 4, 4, 5, 5, 6, 6, 4, 4])
      @c =Daru::Vector.new( [11, 22, 30, 40, 50, 65, 78, 79, 99, 100])
      @y =Daru::Vector.new( [3, 4, 5, 6, 7, 8, 9, 10, 20, 30])
      ds = Daru::DataFrame.new({ :a => @a, :b => @b, :c => @c, :y => @y })
      lr = Statsample::Regression::Multiple::GslEngine.new(ds, :y)
      assert(lr.summary.size > 0)
      model_test(lr, 'gsl')
      predicted = [1.7857, 6.0989, 3.2433, 7.2908, 4.9667, 10.3428, 8.8158, 10.4717, 23.6639, 25.3198]
      c_predicted = lr.predicted
      predicted.each_index{|i|
        assert_in_delta(predicted[i], c_predicted[i], 0.001)
      }
      residuals = [1.2142, -2.0989, 1.7566, -1.29085, 2.033, -2.3428, 0.18414, -0.47177, -3.66395, 4.6801]
      c_residuals = lr.residuals
      residuals.each_index{|i|
        assert_in_delta(residuals[i], c_residuals[i], 0.001)
      }
    else
      skip 'Regression::Multiple::GslEngine not tested (no Gsl)'
    end
  end

  def model_test_matrix(lr, name = 'undefined')
    stan_coeffs = { :a => 0.151, :b => -0.547, :c => 0.997 }
    unstan_coeffs = { :a => 0.695, :b => -4.286, :c => 0.266 }

    unstan_coeffs.each_key{|k|
      assert_in_delta(unstan_coeffs[k], lr.coeffs[k], 0.001, "b coeffs - #{name}")
    }

    stan_coeffs.each_key{|k|
      assert_in_delta(stan_coeffs[k], lr.standarized_coeffs[k], 0.001, "beta coeffs - #{name}")
    }

    assert_in_delta(11.027, lr.constant, 0.001)

    assert_in_delta(0.955, lr.r, 0.001)
    assert_in_delta(0.913, lr.r2, 0.001)

    assert_in_delta(20.908, lr.f, 0.001)
    assert_in_delta(0.001, lr.probability, 0.001)
    assert_in_delta(0.226, lr.tolerance(:a), 0.001)

    coeffs_se = { :a => 1.171, :b => 1.129, :c => 0.072 }

    ccoeffs_se = lr.coeffs_se
    coeffs_se.each_key{|k|
      assert_in_delta(coeffs_se[k], ccoeffs_se[k], 0.001)
    }
    coeffs_t = { :a => 0.594, :b => -3.796, :c => 3.703 }
    ccoeffs_t = lr.coeffs_t
    coeffs_t.each_key{|k|
      assert_in_delta(coeffs_t[k], ccoeffs_t[k], 0.001)
    }

    assert_in_delta(639.6, lr.sst, 0.001)
    assert_in_delta(583.76, lr.ssr, 0.001)
    assert_in_delta(55.840, lr.sse, 0.001)
    assert(lr.summary.size > 0, "#{name} without summary")
  end

  def model_test(lr, name = 'undefined')
    model_test_matrix(lr, name)
    assert_in_delta(4.559, lr.constant_se, 0.001)
    assert_in_delta(2.419, lr.constant_t, 0.001)

    assert_in_delta(1.785, lr.process([1, 3, 11]), 0.001)
  end

  def test_regression_matrix
    @a = Daru::Vector.new([1, 3, 2, 4, 3, 5, 4, 6, 5, 7])
    @b = Daru::Vector.new([3, 3, 4, 4, 5, 5, 6, 6, 4, 4])
    @c = Daru::Vector.new([11, 22, 30, 40, 50, 65, 78, 79, 99, 100])
    @y = Daru::Vector.new([3, 4, 5, 6, 7, 8, 9, 10, 20, 30])
    ds = Daru::DataFrame.new({ :a => @a, :b => @b, :c => @c, :y => @y })
    cor = Statsample::Bivariate.correlation_matrix(ds)

    lr = Statsample::Regression::Multiple::MatrixEngine.new(
      cor, :y, y_mean: @y.mean, 
      x_mean: { :a => ds[:a].mean, :b => ds[:b].mean, :c => ds[:c].mean }, 
      cases: @a.size, y_sd: @y.sd, x_sd: { :a => @a.sd, :b => @b.sd, :c => @c.sd })
    assert_nil(lr.constant_se)
    assert_nil(lr.constant_t)
    model_test_matrix(lr, 'correlation matrix')

    covariance = Statsample::Bivariate.covariance_matrix(ds)
    lr = Statsample::Regression::Multiple::MatrixEngine.new(
      covariance, :y, y_mean: @y.mean, 
      x_mean: { :a => ds[:a].mean, :b => ds[:b].mean, :c => ds[:c].mean }, cases: @a.size)
    assert(lr.summary.size > 0)

    model_test(lr, 'covariance matrix')
  end

  def test_regression_rubyengine
    @a = Daru::Vector.new([nil, 1, 3, 2, 4, 3, 5, 4, 6, 5, 7])
    @b = Daru::Vector.new([nil, 3, 3, 4, 4, 5, 5, 6, 6, 4, 4])
    @c = Daru::Vector.new([nil, 11, 22, 30, 40, 50, 65, 78, 79, 99, 100])
    @y = Daru::Vector.new([nil, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30])
    ds = Daru::DataFrame.new({ :a => @a, :b => @b, :c => @c, :y => @y })
    lr = Statsample::Regression::Multiple::RubyEngine.new(ds, :y)
    assert_equal(11, lr.total_cases)
    assert_equal(10, lr.valid_cases)
    model_test(lr, 'rubyengine with missing data')

    predicted = [nil, 1.7857, 6.0989, 3.2433, 7.2908, 4.9667, 10.3428, 8.8158, 10.4717, 23.6639, 25.3198]
    c_predicted = lr.predicted
    predicted.each_index do |i|
      if c_predicted[i].nil?
        assert(predicted[i].nil?, "Actual #{i} is nil, but expected #{predicted[i]}")
      else
        assert_in_delta(predicted[i], c_predicted[i], 0.001)
      end
    end
    residuals = [nil, 1.2142, -2.0989, 1.7566, -1.29085, 2.033, -2.3428, 0.18414, -0.47177, -3.66395, 4.6801]
    c_residuals = lr.residuals
    residuals.each_index do |i|
      if c_residuals[i].nil?
        assert(residuals[i].nil?)
      else
        assert_in_delta(residuals[i], c_residuals[i], 0.001)
      end
    end
  end
end
