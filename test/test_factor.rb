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
  # Based on Hurdle example
  def test_covariance_matrix
    ds = Daru::DataFrame.from_plaintext(@fixtures_dir + '/bank2.dat', [:v1,:v2,:v3,:v4,:v5,:v6])
    ds.vectors.each {|f|
      ds[f] = ds[f].center
    }
    ds.update
    cm = Statsample::Bivariate.covariance_matrix ds
    pca = Statsample::Factor::PCA.new(cm, m: 6)
    # puts pca.summary
    # puts pca.feature_matrix
    exp_eig = Daru::Vector.new([2.985, 0.931, 0.242, 0.194, 0.085, 0.035])
    assert_similar_vector(exp_eig, Daru::Vector.new(pca.eigenvalues), 0.1)
    pcs = pca.principal_components(ds)
    k = 6
    comp_matrix = pca.component_matrix
    k.times {|i|
      pc_id = "PC_#{i + 1}".to_sym
      k.times {|j| # variable
        ds_id = "v#{j + 1}".to_sym
        r = Statsample::Bivariate.correlation(ds[ds_id], pcs[pc_id])
        assert_in_delta(r, comp_matrix[j, i])
      }
    }
  end

  def test_principalcomponents_ruby_gsl
    if Statsample.has_gsl?
      ran = Distribution::Normal.rng

      #    @r=::Rserve::Connection.new

      samples = 20
      [3, 5, 7].each {|k|
        v = {}
        v[:x0] = Daru::Vector.new(samples.times.map { ran.call }).center
        (1...k).each { |i|
          v["x#{i}".to_sym] = Daru::Vector.new(samples.times.map { |ii| ran.call * 0.5 + v["x#{i - 1}".to_sym][ii] * 0.5 }).center
        }

        ds = Daru::DataFrame.new(v)
        cm = Statsample::Bivariate.covariance_matrix ds
        #      @r.assign('ds',ds)
        #      @r.eval('cm<-cor(ds);sm<-eigen(cm, sym=TRUE);v<-sm$vectors')
        #      puts "eigenvalues"
        #      puts @r.eval('v').to_ruby.to_s
        pca_ruby = Statsample::Factor::PCA.new(cm, m: k, use_gsl: false)
        pca_gsl = Statsample::Factor::PCA.new(cm, m: k, use_gsl: true)
        pc_ruby = pca_ruby.principal_components(ds)
        pc_gsl  = pca_gsl.principal_components(ds)
        # Test component matrix correlation!
        cm_ruby = pca_ruby.component_matrix
        # puts cm_ruby.summary
        k.times {|i|
          pc_id = "PC_#{i + 1}".to_sym
          assert_in_delta(pca_ruby.eigenvalues[i], pca_gsl.eigenvalues[i], 1e-10)
          # Revert gsl component values
          pc_gsl_data = (pc_gsl[pc_id][0] - pc_ruby[pc_id][0]).abs > 1e-6 ? pc_gsl[pc_id].recode(&:-@) : pc_gsl[pc_id]
          assert_similar_vector(pc_gsl_data, pc_ruby[pc_id], 1e-6, "PC for #{k} variables")
          if false
            k.times {|j| # variable
              ds_id = "x#{j}".to_sym
              r = Statsample::Bivariate.correlation(ds[ds_id], pc_ruby[pc_id])
              puts "#{pc_id}-#{ds_id}:#{r}"
            }
          end
        }
      }
    end
    # @r.close
  end

  def test_principalcomponents
    if Statsample.has_gsl?
      principalcomponents(true)
    else
      skip "Require GSL"
    end
    principalcomponents(false)
  end

  def principalcomponents(gsl)
    ran = Distribution::Normal.rng
    samples = 50
    x1 = Daru::Vector.new(samples.times.map { ran.call })
    x2 = Daru::Vector.new(samples.times.map { |i| ran.call * 0.5 + x1[i] * 0.5 })
    ds = Daru::DataFrame.new({ :x1 => x1, :x2 => x2 })

    cm = Statsample::Bivariate.correlation_matrix ds
    r = cm[0, 1]
    pca = Statsample::Factor::PCA.new(cm, m: 2, use_gsl: gsl)
    assert_in_delta(1 + r, pca.eigenvalues[0], 1e-10)
    assert_in_delta(1 - r, pca.eigenvalues[1], 1e-10)
    hs = 1.0 / Math.sqrt(2)
    assert_equal_vector(Vector[1, 1] * hs, pca.eigenvectors[0])
    m_1 = gsl ? Vector[-1, 1] : Vector[1, -1]

    assert_equal_vector(hs * m_1, pca.eigenvectors[1])

    pcs = pca.principal_components(ds)
    exp_pc_1 = ds.collect_row_with_index {|row, _i|
      hs * (row[:x1] + row[:x2])
    }
    exp_pc_2 = ds.collect_row_with_index {|row, _i|
      gsl ? hs * (row[:x2] - row[:x1]) : hs * (row[:x1] - row[:x2])
    }
    assert_similar_vector(exp_pc_1, pcs[:PC_1])
    assert_similar_vector(exp_pc_2, pcs[:PC_2])
  end

  def test_antiimage
    cor = Matrix[[1, 0.964, 0.312], [0.964, 1, 0.411], [0.312, 0.411, 1]]
    expected = Matrix[[0.062, -0.057, 0.074], [-0.057, 0.057, -0.089], [0.074, -0.089, 0.729]]
    ai = Statsample::Factor.anti_image_covariance_matrix(cor)
    assert(Matrix.equal_in_delta?(expected, ai, 0.01), "#{expected} not equal to #{ai}")
  end

  def test_kmo
    @v1 = Daru::Vector.new([1, 2, 3, 4, 7, 8, 9, 10, 14, 15, 20, 50, 60, 70])
    @v2 = Daru::Vector.new([5, 6, 11, 12, 13, 16, 17, 18, 19, 20, 30, 0, 0, 0])
    @v3 = Daru::Vector.new([10, 3, 20, 30, 40, 50, 80, 10, 20, 30, 40, 2, 3, 4])
    # KMO: 0.490
    ds = Daru::DataFrame.new({ :v1 => @v1, :v2 => @v2, :v3 => @v3 })
    cor = Statsample::Bivariate.correlation_matrix(ds)
    kmo = Statsample::Factor.kmo(cor)
    assert_in_delta(0.667, kmo, 0.001)
    assert_in_delta(0.81, Statsample::Factor.kmo(harman_817), 0.01)
  end

  def test_kmo_univariate
    m = harman_817
    expected = [0.73, 0.76, 0.84, 0.87, 0.53, 0.93, 0.78, 0.86]
    m.row_size.times.map {|i|
      assert_in_delta(expected[i], Statsample::Factor.kmo_univariate(m, i), 0.01)
    }
  end
  # Tested with SPSS and R
  def test_pca
    dtype = Statsample.has_gsl? ? :gsl : :array
    a = Daru::Vector.new([2.5, 0.5, 2.2, 1.9, 3.1, 2.3, 2.0, 1.0, 1.5, 1.1], dtype: dtype)
    b = Daru::Vector.new([2.4, 0.7, 2.9, 2.2, 3.0, 2.7, 1.6, 1.1, 1.6, 0.9], dtype: dtype)
    a = a - a.mean
    b = b - b.mean
    ds = Daru::DataFrame.new({ :a => a, :b => b })

    cov_matrix = Statsample::Bivariate.covariance_matrix(ds)
    if Statsample.has_gsl?
      pca = Statsample::Factor::PCA.new(cov_matrix, use_gsl: true)
      pca_set(pca, 'gsl')
    else
      skip('Eigenvalues could be calculated with GSL (requires gsl)')
    end
    pca = Statsample::Factor::PCA.new(cov_matrix, use_gsl: false)
    pca_set(pca, 'ruby')
  end

  def pca_set(pca, _type)
    expected_eigenvalues = [1.284, 0.0490]
    expected_eigenvalues.each_with_index{|ev, i|
      assert_in_delta(ev, pca.eigenvalues[i], 0.001)
    }
    expected_communality = [0.590, 0.694]
    expected_communality.each_with_index{|ev, i|
      assert_in_delta(ev, pca.communalities[i], 0.001)
    }
    expected_cm = [0.768, 0.833]
    obs = pca.component_matrix_correlation(1).column(0).to_a
    expected_cm.each_with_index{|ev, i|
      assert_in_delta(ev, obs[i], 0.001)
    }

    assert(pca.summary)
  end

  # Tested with R
  def test_principalaxis
    matrix = ::Matrix[
    [1.0, 0.709501601093587, 0.877596585880047, 0.272219316266807],  [0.709501601093587, 1.0, 0.291633797330304, 0.871141831433844], [0.877596585880047, 0.291633797330304, 1.0, -0.213373722977167], [0.272219316266807, 0.871141831433844, -0.213373722977167, 1.0]]

    fa = Statsample::Factor::PrincipalAxis.new(matrix, m: 1, max_iterations: 50)

    cm = ::Matrix[[0.923], [0.912], [0.507], [0.483]]

    assert_equal_matrix(cm, fa.component_matrix, 0.001)

    h2 = [0.852, 0.832, 0.257, 0.233]
    h2.each_with_index{|ev, i|
      assert_in_delta(ev, fa.communalities[i], 0.001)
    }
    eigen1 = 2.175
    assert_in_delta(eigen1, fa.eigenvalues[0], 0.001)
    assert(fa.summary.size > 0)
    fa = Statsample::Factor::PrincipalAxis.new(matrix, smc: false)

    assert_raise RuntimeError do
      fa.iterate
    end
  end

  def test_rotation_varimax
    a = Matrix[[0.4320,  0.8129,  0.3872],
               [0.7950, -0.5416,  0.2565],
               [0.5944,  0.7234, -0.3441],
               [0.8945, -0.3921, -0.1863]]

    expected = Matrix[[-0.0204423,     0.938674,    -0.340334],
                      [0.983662, 0.0730206, 0.134997],
                      [0.0826106, 0.435975, -0.893379],
                      [0.939901, -0.0965213, -0.309596]]
    varimax = Statsample::Factor::Varimax.new(a)
    assert(!varimax.rotated.nil?, "Rotated shouldn't be empty")
    assert(!varimax.component_transformation_matrix.nil?, "Component matrix shouldn't be empty")
    assert(!varimax.h2.nil?, "H2 shouldn't be empty")

    assert_equal_matrix(expected, varimax.rotated, 1e-6)
    assert(varimax.summary.size > 0)
  end
end
