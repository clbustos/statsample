$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'test/unit'
require 'statsample'

class StatsampleMatrixTestCase < Test::Unit::TestCase
    def setup
    end
    def test_subindex
      matrix=Matrix[[1,2,3],[4,5,6],[7,8,9]]
      assert_equal(5, matrix[1,1])
      assert_equal(Matrix[[1,2,3]], matrix[0,:*])
      assert_equal(Matrix[[1],[4],[7]], matrix[:*,0])
      assert_equal(Matrix[[1,2],[4,5],[7,8]], matrix[:*,0..1])
      assert_equal(Matrix[[1,2],[4,5]], matrix[0..1,0..1])
    end
    def test_sums
      matrix=Matrix[[1,2,3],[4,5,6],[7,8,9]]
      assert_equal(6,matrix.row_sum[0])
      assert_equal(12,matrix.column_sum[0])
      assert_equal(45,matrix.total_sum)
      m=matrix.to_gsl
    end
    def test_covariate
      a=Matrix[[1.0, 0.3, 0.2], [0.3, 1.0, 0.5], [0.2, 0.5, 1.0]]
      a.extend Statsample::CovariateMatrix
      a.fields=%w{a b c}
      assert_equal(:correlation, a.type)
      
      assert_equal(Matrix[[0.5],[0.3]], a.submatrix(%w{c a}, %w{b}))
      assert_equal(Matrix[[1.0, 0.2] , [0.2, 1.0]], a.submatrix(%w{c a}))
      assert_equal(:correlation, a.submatrix(%w{c a}).type)
      
      a=Matrix[[20,30,10], [30,60,50], [10,50,50]]
      
      a.extend Statsample::CovariateMatrix
      
      assert_equal(:covariance, a.type)
      
      a=100.times.collect {rand()}.to_scale
      b=100.times.collect {rand()}.to_scale
      c=100.times.collect {rand()}.to_scale
      ds={'a'=>a,'b'=>b,'c'=>c}.to_dataset
      corr=Statsample::Bivariate.correlation_matrix(ds)
      real=Statsample::Bivariate.covariance_matrix(ds).correlation
      corr.row_size.times do |i|
        corr.column_size.times do |j|
          assert_in_delta(corr[i,j], real[i,j],1e-15)
        end
      end
     
      
    end
end