$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'test/unit'
class StatsampleFactorTestCase < Test::Unit::TestCase
    def test_pca
      if HAS_GSL
        require 'gsl'
        a=[2.5, 0.5, 2.2, 1.9, 3.1, 2.3, 2.0, 1.0, 1.5, 1.1].to_scale
        b=[2.4,0.7,2.9,2.2,3.0,2.7,1.6,1.1,1.6,0.9].to_scale
        a.recode! {|c| c-a.mean}
        b.recode! {|c| c-b.mean}
        ds={'a'=>a,'b'=>b}.to_dataset
        cov_matrix=Statsample::Bivariate.covariance_matrix(ds)
        pca=Statsample::Factor::PCA.new(cov_matrix)
        expected_eigenvalues=[1.284, 0.0490]
        expected_eigenvalues.each_with_index{|ev,i|
          assert_in_delta(ev,pca.eigenvalues[i],0.001)
        }
        expected_fm_1=GSL::Matrix[[0.677], [0.735]]
        expected_fm_2=GSL::Matrix[[0.677,0.735], [0.735, -0.677]]
        _test_matrix(expected_fm_1,pca.feature_vector(1))
        _test_matrix(expected_fm_2,pca.feature_vector(2))
      else
        puts "PCA not tested. Requires GSL"
      end
    end
    def test_rotation_varimax
      if HAS_GSL
        a = Matrix[ [ 0.4320,  0.8129,  0.3872]  ,
         [0.7950, -0.5416,  0.2565]  ,
         [0.5944,  0.7234, -0.3441],
         [0.8945, -0.3921, -0.1863] ]
         expected= Matrix[[-0.0204423,     0.938674,    -0.340334],
         [0.983662, 0.0730206, 0.134997],
         [0.0826106, 0.435975, -0.893379],
         [0.939901, -0.0965213, -0.309596]].to_gsl
         varimax=Statsample::Factor::Varimax.new(a)
         varimax.iterate
         _test_matrix(expected,varimax.rotated)
       else
         puts "Rotation not tested. Requires GSL"
       end
    end
    def _test_matrix(a,b)
      a.size1.times {|i|
        a.size2.times {|j|
          assert_in_delta(a[i,j], b[i,j],0.001)
        }
      }
    end
end
