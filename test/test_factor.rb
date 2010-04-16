require(File.dirname(__FILE__)+'/helpers_tests.rb')

class StatsampleFactorTestCase < MiniTest::Unit::TestCase
  # Tested with SPSS and R
  def test_pca
    if Statsample.has_gsl?
      require 'gsl'
      a=[2.5, 0.5, 2.2, 1.9, 3.1, 2.3, 2.0, 1.0, 1.5, 1.1].to_scale
      b=[2.4, 0.7, 2.9, 2.2, 3.0, 2.7, 1.6, 1.1, 1.6, 0.9].to_scale
      a.recode! {|c| c-a.mean}
      b.recode! {|c| c-b.mean}
      ds={'a'=>a,'b'=>b}.to_dataset
      cov_matrix=Statsample::Bivariate.covariance_matrix(ds)
      pca=Statsample::Factor::PCA.new(cov_matrix)
      expected_eigenvalues=[1.284, 0.0490]
      expected_eigenvalues.each_with_index{|ev,i|
        assert_in_delta(ev,pca.eigenvalues[i],0.001)
      }
      expected_communality=[0.590, 0.694]
      expected_communality.each_with_index{|ev,i|
        assert_in_delta(ev,pca.communalities[i],0.001)
      }
      expected_cm=[0.768, 0.833]

      obs=pca.component_matrix(1).column(0).to_a
      expected_cm.each_with_index{|ev,i|
        assert_in_delta(ev,obs[i],0.001)
      }

      expected_fm_1=GSL::Matrix[[0.677], [0.735]]
      expected_fm_2=GSL::Matrix[[0.677,0.735], [0.735, -0.677]]
      _test_matrix(expected_fm_1,pca.feature_vector(1))
      _test_matrix(expected_fm_2,pca.feature_vector(2))
      assert(pca.summary)
    else
      skip "PCA not tested. Requires GSL"
    end
  end

  # Tested with R
  def test_principalaxis
    if Statsample.has_gsl?
      require 'gsl'
      matrix=Matrix[
      [1.0, 0.709501601093587, 0.877596585880047, 0.272219316266807],  [0.709501601093587, 1.0, 0.291633797330304, 0.871141831433844], [0.877596585880047, 0.291633797330304, 1.0, -0.213373722977167], [0.272219316266807, 0.871141831433844, -0.213373722977167, 1.0]]
      fa=Statsample::Factor::PrincipalAxis.new(matrix,:m=>1)
      
      cm=Matrix[[0.923],[0.912],[0.507],[0.483]].to_gsl
      
      _test_matrix(cm,fa.component_matrix)
      
      h2=[0.852,0.832,0.257,0.233]
      h2.each_with_index{|ev,i|
        assert_in_delta(ev,fa.communalities[i],0.001)
      }
      eigen1=2.175
      assert_in_delta(eigen1, fa.eigenvalues[0],0.001)

      fa=Statsample::Factor::PrincipalAxis.new(matrix,:smc=>false)
      assert_raise RuntimeError do
        fa.iterate

      end



      assert(fa.summary)

    else
      skip "Principal Axis not tested. Requires GSL"
    end
  end


  def test_rotation_varimax
    if Statsample.has_gsl?
      a = Matrix[ [ 0.4320,  0.8129,  0.3872]  ,
        [0.7950, -0.5416,  0.2565]  ,
        [0.5944,  0.7234, -0.3441],
      [0.8945, -0.3921, -0.1863] ]

      expected= Matrix[[-0.0204423,     0.938674,    -0.340334],
        [0.983662, 0.0730206, 0.134997],
        [0.0826106, 0.435975, -0.893379],
      [0.939901, -0.0965213, -0.309596]].to_gsl
      varimax=Statsample::Factor::Varimax.new(a)
      assert(!varimax.rotated.nil?, "Rotated shouldn't be empty")
      assert(!varimax.component_transformation_matrix.nil?, "Component matrix shouldn't be empty")
      assert(!varimax.h2.nil?,"H2 shouldn't be empty")
      _test_matrix(expected,varimax.rotated)
    else
      skip "Rotation not tested. Requires GSL"
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
