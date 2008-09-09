require File.dirname(__FILE__)+'/../lib/rubyss'
require 'rubyss/dataset'
require 'rubyss/test'
require 'rubyss/correlation'
require 'test/unit'

class RubySSStatisicsTestCase < Test::Unit::TestCase

	def initialize(*args)
		super
	end
    def test_chi_square
        assert_raise TypeError do
            RubySS::Test.chi_square(1,1)
        end
        real=Matrix[[95,95],[45,155]]
        expected=Matrix[[68,122],[72,128]]
        assert_nothing_raised do
            chi=RubySS::Test.chi_square(real,expected)
        end
        chi=RubySS::Test.chi_square(real,expected)
        assert_in_delta(32.53,chi,0.1)
    end
    def test_correlations
        v1=[6,5,4,7,8,4,3,2].to_vector(:scale)
        v2=[2,3,7,8,6,4,3,2].to_vector(:scale)
        assert_in_delta(0.53,RubySS::Correlation.pearson(v1,v2),0.01)
        v3=[6,2,  5,4,7,8,4,3,2,nil].to_vector(:scale)
        v4=[2,nil,3,7,8,6,4,3,2,500].to_vector(:scale)
        assert_in_delta(0.53,RubySS::Correlation.pearson(v3,v4),0.01)
    end
    def test_estimation_mean              
        v=([42]*23+[41]*4+[36]*1+[32]*1+[29]*1+[27]*2+[23]*1+[19]*1+[16]*2+[15]*2+[14,11,10,9,7]+ [6]*3+[5]*2+[4,3]).to_vector(:scale)
        assert_equal(50,v.size)
        assert_equal(1471,v.sum())
        limits=RubySS::mean_confidence_interval_z(v.mean(),v.sds(),v.size,676,0.80)
        p limits[0]*(676)
    end
    def test_estimation_proportion
        assert_in_delta(6686, RubySS::total_variance_sample(0.19,200,3042),0.1)
        v=([1]*38+[0]*162).to_vector
        assert_in_delta(6686, v.variance_total(3042) , 0.1)
        limits=RubySS::proportion_confidence_interval_t(0.37, 100, 500, 0.95)
        assert_in_delta(0.280,limits[0] ,0.005)
        assert_in_delta(0.460,limits[1] ,0.005)
        v=([1]*37+[0]*63).to_vector
        limits=v.proportion_confidence_interval_t(500, 0.95)
        assert_in_delta(0.280,limits[0] ,0.005)
        assert_in_delta(0.460,limits[1] ,0.005)
        limits=v.proportion_confidence_interval_z(500, 0.95)
        assert_in_delta(0.280,limits[0] ,0.005)
        assert_in_delta(0.460,limits[1] ,0.005)        
    end
    
end