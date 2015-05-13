require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleMatrixTestCase < Minitest::Test
  def test_to_dataset
    m = Matrix[[1, 4], [2, 5], [3, 6]]
    m.extend Statsample::NamedMatrix
    m.fields_y = %w(x1 x2)
    m.name = 'test'
    samples = 100
    x1 = [1, 2, 3].to_numeric
    x2 = [4, 5, 6].to_numeric
    ds = { 'x1' => x1, 'x2' => x2 }.to_dataset
    ds.name = 'test'
    obs = m.to_dataset
    assert_equal(ds['x1'], obs['x1'])
    assert_equal(ds['x2'], obs['x2'])
    assert_equal(ds['x1'].mean, obs['x1'].mean)
  end

  def test_covariate
    a = Matrix[[1.0, 0.3, 0.2], [0.3, 1.0, 0.5], [0.2, 0.5, 1.0]]
    a.extend Statsample::CovariateMatrix
    a.fields = %w(a b c)
    assert_equal(:correlation, a._type)

    assert_equal(Matrix[[0.5], [0.3]], a.submatrix(%w(c a), %w(b)))
    assert_equal(Matrix[[1.0, 0.2], [0.2, 1.0]], a.submatrix(%w(c a)))
    assert_equal(:correlation, a.submatrix(%w(c a))._type)

    a = Matrix[[20, 30, 10], [30, 60, 50], [10, 50, 50]]

    a.extend Statsample::CovariateMatrix

    assert_equal(:covariance, a._type)

    a = 50.times.collect { rand }.to_numeric
    b = 50.times.collect { rand }.to_numeric
    c = 50.times.collect { rand }.to_numeric
    ds = { 'a' => a, 'b' => b, 'c' => c }.to_dataset
    corr = Statsample::Bivariate.correlation_matrix(ds)
    real = Statsample::Bivariate.covariance_matrix(ds).correlation
    corr.row_size.times do |i|
      corr.column_size.times do |j|
        assert_in_delta(corr[i, j], real[i, j], 1e-15)
      end
    end
  end
end
