require File.dirname(__FILE__)+'/../lib/rubyss'
require 'test/unit'
require 'rubyss/regression'
class RubySSRegressionTestCase < Test::Unit::TestCase
	def initialize(*args)
		@x=[13,20,10,33,15].to_vector(:scale)
		@y=[23,18,35,10,27	].to_vector(:scale)
		@reg=RubySS::Regression::SimpleRegression.new_from_vectors(@x,@y)
		super
	end
	def test_parameters
		assert_in_delta(40.009, @reg.a,0.001)
		assert_in_delta(-0.957, @reg.b,0.001)
		assert_in_delta(4.248,@reg.standard_error,0.002)
	end
    def test_multiple_regression
        @a=[1,3,2,4,3,5,4,6,5,7].to_vector(:scale)
        @b=[3,3,4,4,5,5,6,6,4,4].to_vector(:scale)
        @c=[11,22,30,40,50,65,78,79,99,100].to_vector(:scale)
        @y=[3,4,5,6,7,8,9,10,20,30].to_vector(:scale)
        ds={'a'=>@a,'b'=>@b,'c'=>@c,'y'=>@y}.to_dataset
        lr=RubySS::Regression::MultipleRegression.new_from_dataset(ds,'y')
        
        assert_in_delta(0.695,lr.coeffs[0],0.001)
        assert_in_delta(11.027,lr.constant,0.001)
        assert_in_delta(1.785,lr.process([1,3,11]),0.001)
        predicted=[1.7857, 6.0989, 3.2433, 7.2908, 4.9667, 10.3428, 8.8158, 10.4717, 23.6639, 25.3198]
        c_predicted=lr.predicted
        predicted.each_index{|i|
            assert_in_delta(predicted[i],c_predicted[i],0.001)
        }
        residuals=[1.2142, -2.0989, 1.7566, -1.29085, 2.033, -2.3428, 0.18414, -0.47177, -3.66395, 4.6801]
        c_residuals=lr.residuals
        residuals.each_index{|i|
            assert_in_delta(residuals[i],c_residuals[i],0.001)
        }
        
        s_coeffs=[0.151,-0.547,0.997]
        cs_coeefs=lr.standarized_coeffs
        s_coeffs.each_index{|i|
            assert_in_delta(s_coeffs[i],cs_coeefs[i],0.001)
        }
        assert_in_delta(639.6,lr.sst,0.001)
        assert_in_delta(583.76,lr.ssr,0.001)
        assert_in_delta(55.840,lr.sse,0.001)
        assert_in_delta(0.955,lr.r,0.001)
        assert_in_delta(0.913,lr.r2,0.001)
        assert_in_delta(20.908, lr.f,0.001)
        assert_in_delta(0.001, lr.significance, 0.001)
        
    end
end