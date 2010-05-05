require(File.dirname(__FILE__)+'/helpers_tests.rb')

require 'distribution'


class DistributionTestCase < MiniTest::Unit::TestCase
  def test_chi
    if Distribution.has_gsl?
      [2,3,4,5].each{|k|
        chis=rand()*10
        area=Distribution::ChiSquare.cdf(chis, k)
        assert_in_delta(area, GSL::Cdf.chisq_P(chis,k),0.0001)
        assert_in_delta(chis, Distribution::ChiSquare.p_value(area,k),0.0001,"Error on prob #{area} and k #{k}")
      }
    end
  end
  def test_t
    if Distribution.has_gsl?
      [-2,0.1,0.5,1,2].each{|t|
        [2,5,10].each{|n|
          area=Distribution::T.cdf(t,n)
          assert_in_delta(area, GSL::Cdf.tdist_P(t,n),0.0001)
          assert_in_delta(Distribution::T.p_value(area,n), GSL::Cdf.tdist_Pinv(area,n),0.0001)

        }
      }
    end
  end
  def test_normal
    if Distribution.has_gsl?
      [-2,0.1,0.5,1,2].each{|x|
        area=Distribution::Normal.cdf(x)
        assert_in_delta(area, GSL::Cdf.ugaussian_P(x),0.0001)
        assert_in_delta(Distribution::Normal.p_value(area), GSL::Cdf.ugaussian_Pinv(area),0.0001)
        assert_in_delta(Distribution::Normal.pdf(x), GSL::Ran::ugaussian_pdf(x),0.0001)
      }
    end
  end
  def test_normal_bivariate
    if Distribution.has_gsl?
      [0.2,0.4,0.6,0.8,0.9, 0.99,0.999,0.999999].each {|rho|
        assert_in_delta(GSL::Ran::bivariate_gaussian_pdf(0, 0, 1,1,rho), Distribution::NormalBivariate.pdf(0,0, rho , 1,1),1e-8)

      }
    end

    [-3,-2,-1,0,1,1.5].each {|x|
      assert_in_delta(Distribution::NormalBivariate.cdf_hull(x,x,0.5), Distribution::NormalBivariate.cdf_genz(x,x,0.5), 0.001)
      #assert_in_delta(Distribution::NormalBivariate.cdf_genz(x,x,0.5), Distribution::NormalBivariate.cdf_jantaravareerat(x,x,0.5), 0.001)
    }

    assert_in_delta(0.686, Distribution::NormalBivariate.cdf(2,0.5,0.5), 0.001)
    assert_in_delta(0.498, Distribution::NormalBivariate.cdf(2,0.0,0.5), 0.001)
    assert_in_delta(0.671, Distribution::NormalBivariate.cdf(1.5,0.5,0.5), 0.001)

    assert_in_delta(Distribution::Normal.cdf(0), Distribution::NormalBivariate.cdf(10,0,0.9), 0.001)
  end
  def test_f
    if Distribution.has_gsl?
      [0.1,0.5,1,2,10,20,30].each{|f|
        [2,5,10].each{|n2|
          [2,5,10].each{|n1|
            area=Distribution::F.cdf(f,n1,n2)
            assert_in_delta(area, GSL::Cdf.fdist_P(f,n1,n2),0.0001)
            assert_in_delta(Distribution::F.p_value(area,n1,n2), GSL::Cdf.fdist_Pinv(area,n1,n2),0.0001)

          }
        }
      }
    end
  end

end
