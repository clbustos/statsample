require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleBivariateTestCase < Minitest::Test
  should 'method sum of squares should be correct' do
    v1 = Daru::Vector.new([1, 2, 3, 4, 5, 6])
    v2 = Daru::Vector.new([6, 2, 4, 10, 12, 8])
    assert_equal(23.0, Statsample::Bivariate.sum_of_squares(v1, v2))
  end
  should_with_gsl 'return same covariance with ruby and gls implementation' do
    v1 = Daru::Vector.new(20.times.collect { |_a| rand })
    v2 = Daru::Vector.new(20.times.collect { |_a| rand })
    assert_in_delta(Statsample::Bivariate.covariance(v1, v2), Statsample::Bivariate.covariance_slow(v1, v2), 0.001)
  end

  should_with_gsl 'return same correlation with ruby and gls implementation' do
    v1 = Daru::Vector.new(20.times.collect { |_a| rand })
    v2 = Daru::Vector.new(20.times.collect { |_a| rand })

    assert_in_delta(GSL::Stats.correlation(v1.to_gsl, v2.to_gsl), Statsample::Bivariate.pearson_slow(v1, v2), 1e-10)
  end
  should 'return correct pearson correlation' do
    v1 = Daru::Vector.new([6, 5, 4, 7, 8, 4, 3, 2])
    v2 = Daru::Vector.new([2, 3, 7, 8, 6, 4, 3, 2])
    assert_in_delta(0.525, Statsample::Bivariate.pearson(v1, v2), 0.001)
    assert_in_delta(0.525, Statsample::Bivariate.pearson_slow(v1, v2), 0.001)

    v3 = Daru::Vector.new([6, 2,  1000, 1000, 5, 4, 7, 8, 4, 3, 2, nil])
    v4 = Daru::Vector.new([2, nil, nil, nil,  3, 7, 8, 6, 4, 3, 2, 500])
    assert_in_delta(0.525, Statsample::Bivariate.pearson(v3, v4), 0.001)
    # Test ruby method
    v3a, v4a = Statsample.only_valid v3, v4
    assert_in_delta(0.525, Statsample::Bivariate.pearson_slow(v3a, v4a), 0.001)
  end
  should 'return correct values for t_pearson and prop_pearson' do
    v1 = Daru::Vector.new([6, 5, 4, 7, 8, 4, 3, 2])
    v2 = Daru::Vector.new([2, 3, 7, 8, 6, 4, 3, 2])
    r = Statsample::Bivariate::Pearson.new(v1, v2)
    assert_in_delta(0.525, r.r, 0.001)
    assert_in_delta(Statsample::Bivariate.t_pearson(v1, v2), r.t, 0.001)
    assert_in_delta(Statsample::Bivariate.prop_pearson(r.t, 8, :both), r.probability, 0.001)
    assert(r.summary.size > 0)
  end
  should 'return correct correlation_matrix with nils values' do
    v1 = Daru::Vector.new([6, 5, 4, 7, 8, 4, 3, 2])
    v2 = Daru::Vector.new([2, 3, 7, 8, 6, 4, 3, 2])
    v3 = Daru::Vector.new([6, 2,  1000, 1000, 5, 4, 7, 8])
    v4 = Daru::Vector.new([2, nil, nil, nil,  3, 7, 8, 6])
    ds = Daru::DataFrame.new({ :v1 => v1, :v2 => v2, :v3 => v3, :v4 => v4 })
    c = proc { |n1, n2| Statsample::Bivariate.pearson(n1, n2) }
    expected = Matrix[[c.call(v1, v1), c.call(v1, v2), c.call(v1, v3), c.call(v1, v4)], [c.call(v2, v1), c.call(v2, v2), c.call(v2, v3), c.call(v2, v4)], [c.call(v3, v1), c.call(v3, v2), c.call(v3, v3), c.call(v3, v4)],
                      [c.call(v4, v1), c.call(v4, v2), c.call(v4, v3), c.call(v4, v4)]
    ]
    obt = Statsample::Bivariate.correlation_matrix(ds)
    for i in 0...expected.row_size
      for j in 0...expected.column_size
        # puts expected[i,j].inspect
        # puts obt[i,j].inspect
        assert_in_delta(expected[i, j], obt[i, j], 0.0001, "#{expected[i, j].class}!=#{obt[i, j].class}  ")
      end
    end
    # assert_equal(expected,obt)
  end
  should_with_gsl 'return same values for optimized and pairwise covariance matrix' do
    cases = 100
    v1 = Daru::Vector.new_with_size(cases) { rand }
    v2 = Daru::Vector.new_with_size(cases) { rand }
    v3 = Daru::Vector.new_with_size(cases) { rand }
    v4 = Daru::Vector.new_with_size(cases) { rand }
    v5 = Daru::Vector.new_with_size(cases) { rand }

    ds = Daru::DataFrame.new({ :v1 => v1, :v2 => v2, :v3 => v3, :v4 => v4, :v5 => v5 })

    cor_opt = Statsample::Bivariate.covariance_matrix_optimized(ds)

    cor_pw = Statsample::Bivariate.covariance_matrix_pairwise(ds)
    assert_equal_matrix(cor_opt, cor_pw, 1e-15)
  end
  should_with_gsl 'return same values for optimized and pairwise correlation matrix' do
    cases = 100
    v1 = Daru::Vector.new_with_size(cases) { rand }
    v2 = Daru::Vector.new_with_size(cases) { rand }
    v3 = Daru::Vector.new_with_size(cases) { rand }
    v4 = Daru::Vector.new_with_size(cases) { rand }
    v5 = Daru::Vector.new_with_size(cases) { rand }

    ds = Daru::DataFrame.new({ 
      :v1 => v1, :v2 => v2, :v3 => v3, :v4 => v4, :v5 => v5 })

    cor_opt = Statsample::Bivariate.correlation_matrix_optimized(ds)

    cor_pw = Statsample::Bivariate.correlation_matrix_pairwise(ds)
    assert_equal_matrix(cor_opt, cor_pw, 1e-15)
  end
  should 'return correct correlation_matrix without nils values' do
    v1 = Daru::Vector.new([6, 5, 4, 7, 8, 4, 3, 2])
    v2 = Daru::Vector.new([2, 3, 7, 8, 6, 4, 3, 2])
    v3 = Daru::Vector.new([6, 2,  1000, 1000, 5, 4, 7, 8])
    v4 = Daru::Vector.new([2, 4, 6, 7,  3, 7, 8, 6])
    ds = Daru::DataFrame.new({ :v1 => v1, :v2 => v2, :v3 => v3, :v4 => v4 })
    c = proc { |n1, n2| Statsample::Bivariate.pearson(n1, n2) }
    expected = Matrix[[c.call(v1, v1), c.call(v1, v2), c.call(v1, v3), c.call(v1, v4)], [c.call(v2, v1), c.call(v2, v2), c.call(v2, v3), c.call(v2, v4)], [c.call(v3, v1), c.call(v3, v2), c.call(v3, v3), c.call(v3, v4)],
                      [c.call(v4, v1), c.call(v4, v2), c.call(v4, v3), c.call(v4, v4)]
    ]
    obt = Statsample::Bivariate.correlation_matrix(ds)
    for i in 0...expected.row_size
      for j in 0...expected.column_size
        # puts expected[i,j].inspect
        # puts obt[i,j].inspect
        assert_in_delta(expected[i, j], obt[i, j], 0.0001, "#{expected[i, j].class}!=#{obt[i, j].class}  ")
      end
    end
    # assert_equal(expected,obt)
  end

  should 'return correct value for prop pearson' do
    assert_in_delta(0.42, Statsample::Bivariate.prop_pearson(Statsample::Bivariate.t_r(0.084, 94), 94), 0.01)
    assert_in_delta(0.65, Statsample::Bivariate.prop_pearson(Statsample::Bivariate.t_r(0.046, 95), 95), 0.01)
    r = 0.9
    n = 100
    t = Statsample::Bivariate.t_r(r, n)
    assert(Statsample::Bivariate.prop_pearson(t, n, :both) < 0.05)
    assert(Statsample::Bivariate.prop_pearson(t, n, :right) < 0.05)
    assert(Statsample::Bivariate.prop_pearson(t, n, :left) > 0.05)

    r = -0.9
    n = 100
    t = Statsample::Bivariate.t_r(r, n)
    assert(Statsample::Bivariate.prop_pearson(t, n, :both) < 0.05)
    assert(Statsample::Bivariate.prop_pearson(t, n, :right) > 0.05)
    assert(Statsample::Bivariate.prop_pearson(t, n, :left) < 0.05)
  end

  should "return correct value for Spearman's rho" do
    v1 =Daru::Vector.new( [86, 97, 99, 100, 101, 103, 106, 110, 112, 113])
    v2 =Daru::Vector.new( [0, 20, 28, 27, 50, 29, 7, 17, 6, 12])
    assert_in_delta(-0.175758, Statsample::Bivariate.spearman(v1, v2), 0.0001)
  end
  should 'return correct value for point_biserial correlation' do
    c = Daru::Vector.new([1, 3, 5, 6, 7, 100, 200, 300, 400, 300])
    d = Daru::Vector.new([1, 1, 1, 1, 1, 0, 0, 0, 0, 0])
    assert_raises TypeError do
      Statsample::Bivariate.point_biserial(c, d)
    end
    assert_in_delta(Statsample::Bivariate.point_biserial(d, c), Statsample::Bivariate.pearson(d, c), 0.0001)
  end
  should 'return correct value for tau_a and tau_b' do
    v1 = Daru::Vector.new([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
    v2 = Daru::Vector.new([1, 3, 4, 5, 7, 8, 2, 9, 10, 6, 11])
    assert_in_delta(0.6727, Statsample::Bivariate.tau_a(v1, v2), 0.001)
    assert_in_delta(0.6727, Statsample::Bivariate.tau_b((Statsample::Crosstab.new(v1, v2).to_matrix)), 0.001)
    v1 = Daru::Vector.new([12, 14, 14, 17, 19, 19, 19, 19, 19, 20, 21, 21, 21, 21, 21, 22, 23, 24, 24, 24, 26, 26, 27])
    v2 = Daru::Vector.new([11, 4, 4, 2, 0, 0, 0, 0, 0, 0, 4, 0, 4, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0])
    assert_in_delta(-0.376201540231705, Statsample::Bivariate.tau_b(Statsample::Crosstab.new(v1, v2).to_matrix), 0.001)
  end
  should 'return correct value for gamma correlation' do
    m = Matrix[[10, 5, 2], [10, 15, 20]]
    assert_in_delta(0.636, Statsample::Bivariate.gamma(m), 0.001)
    m2 = Matrix[[15, 12, 6, 5], [12, 8, 10, 8], [4, 6, 9, 10]]
    assert_in_delta(0.349, Statsample::Bivariate.gamma(m2), 0.001)
  end

  should 'return correct residuals' do
    # TODO: test Statsample::Bivariate.residuals
  end
end
