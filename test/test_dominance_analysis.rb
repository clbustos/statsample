require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleDominanceAnalysisTestCase < Minitest::Test
  def test_dominance_univariate
    # Example from Budescu (1993)
    m = Matrix[[1, 0.683, 0.154, 0.460, 0.618], [0.683, 1, -0.050, 0.297, 0.461], [0.154, -0.050, 1, 0.006, 0.262], [0.460, 0.297, 0.006, 1, 0.507], [0.618, 0.461, 0.262, 0.507, 1]]
    m.extend Statsample::CovariateMatrix
    m.fields = %w(x1 x2 x3 x4 y)
    da = Statsample::DominanceAnalysis.new(m, 'y')

    contr_x1 = { 'x2' => 0.003, 'x3' => 0.028, 'x4' => 0.063 }
    contr_x1.each  do |k, v|
      assert_in_delta(v, da.models_data[['x1']].contributions[k], 0.001)
    end
    assert_in_delta(0.052, da.models_data[%w(x2 x3 x4)].contributions['x1'], 0.001)
    expected_dominances = [1, 1, 0.5, 0.5, 0, 0]
    expected_g_dominances = [1, 1, 1, 1, 0, 0]

    da.pairs.each_with_index do |a, i|
      assert_equal(expected_dominances[i], da.total_dominance_pairwise(a[0], a[1]))
      assert_equal(expected_dominances[i], da.conditional_dominance_pairwise(a[0], a[1]))
      assert_equal(expected_g_dominances[i], da.general_dominance_pairwise(a[0], a[1]))
    end
    assert(da.summary.size > 0)
  end

  def test_dominance_multivariate
    m = Matrix[[1.0, -0.19, -0.358, -0.343, 0.359, 0.257], [-0.19, 1.0, 0.26, 0.29, -0.11, -0.11], [-0.358, 0.26, 1.0, 0.54, -0.49, -0.23], [-0.343, 0.29, 0.54, 1.0, -0.22, -0.41], [0.359, -0.11, -0.49, -0.22, 1.0, 0.62], [0.257, -0.11, -0.23, -0.41, 0.62, 1]]
    m.extend Statsample::CovariateMatrix
    m.fields = %w(y1 y2 x1 x2 x3 x4)
    m2 = m.submatrix(%w(y1 x1 x2 x3 x4))

    da = Statsample::DominanceAnalysis.new(m, %w(y1 y2), cases: 683, method_association: :p2yx)

    contr_x1 = { 'x2' => 0.027, 'x3' => 0.024, 'x4' => 0.017 }
    contr_x1.each  do |k, v|
      assert_in_delta(v, da.models_data[['x1']].contributions[k], 0.003)
    end
  end
end
