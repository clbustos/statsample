$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'distribution'
require 'test/unit'
begin
    require 'rbgsl'
    NOT_GSL=false
rescue LoadError
    NOT_GSL=true
end
class DistributionTestCase < Test::Unit::TestCase
    def test_chi
        if !NOT_GSL
        [2,3,4,5].each{|k|
            chis=rand()*10
            area=Distribution::ChiSquare.cdf(chis, k)
            assert_in_delta(area, GSL::Cdf.chisq_P(chis,k),0.0001)
            assert_in_delta(chis, Distribution::ChiSquare.p_value(area,k),0.0001,"Error on prob #{area} and k #{k}")
        }
        end
    end
    def test_t
        if !NOT_GSL
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
        if !NOT_GSL
            [-2,0.1,0.5,1,2].each{|x|
                area=Distribution::Normal.cdf(x)
                assert_in_delta(area, GSL::Cdf.ugaussian_P(x),0.0001)
                assert_in_delta(Distribution::Normal.p_value(area), GSL::Cdf.ugaussian_Pinv(area),0.0001)
                assert_in_delta(Distribution::Normal.pdf(x), GSL::Ran::ugaussian_pdf(x),0.0001)
            }
        end
    end
    def test_f
        if !NOT_GSL
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