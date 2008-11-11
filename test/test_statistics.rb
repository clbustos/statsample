require File.dirname(__FILE__)+'/../lib/rubyss'
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
    def test_pearson
        v1=[6,5,4,7,8,4,3,2].to_vector(:scale)
        v2=[2,3,7,8,6,4,3,2].to_vector(:scale)
        assert_in_delta(0.53,RubySS::Correlation.pearson(v1,v2),0.01)
        v3=[6,2,  1000,1000,5,4,7,8,4,3,2,nil].to_vector(:scale)
        v4=[2,nil,nil,nil,  3,7,8,6,4,3,2,500].to_vector(:scale)
        assert_in_delta(0.53,RubySS::Correlation.pearson(v3,v4),0.01)
    end
	def test_spearman
		v1=[86,97,99,100,101,103,106,110,112,113].to_vector(:scale)
		v2=[0,20,28,27,50,29,7,17,6,12].to_vector(:scale)
        assert_in_delta(-0.175758,RubySS::Correlation.spearman(v1,v2),0.0001)
	end
	def test_point_biserial
		c=[1,3,5,6,7,100,200,300,400,300].to_vector(:scale)
		d=[1,1,1,1,1,0,0,0,0,0].to_vector(:scale)
		assert_raise TypeError do
			RubySS::Correlation.point_biserial(c,d)
		end
		assert_in_delta(RubySS::Correlation.point_biserial(d,c), RubySS::Correlation.pearson(d,c),0.0001)
	end
	def test_tau
		v1=[1,2,3,4,5,6,7,8,9,10,11].to_vector(:ordinal)
		v2=[1,3,4,5,7,8,2,9,10,6,11].to_vector(:ordinal)
		assert_in_delta(0.6727,RubySS::Correlation.tau_a(v1,v2),0.001)
		assert_in_delta(0.6727,RubySS::Correlation.tau_b((RubySS::Crosstab.new(v1,v2).to_matrix)),0.001)
		v1=[12,14,14,17,19,19,19,19,19,20,21,21,21,21,21,22,23,24,24,24,26,26,27].to_vector(:ordinal)
		v2=[11,4,4,2,0,0,0,0,0,0,4,0,4,0,0,0,0,4,0,0,0,0,0].to_vector(:ordinal)
		assert_in_delta(-0.376201540231705, RubySS::Correlation.tau_b(RubySS::Crosstab.new(v1,v2).to_matrix),0.001)
	end
	def test_gamma
		m=Matrix[[10,5,2],[10,15,20]]
		assert_in_delta(0.636,RubySS::Correlation.gamma(m),0.001)
		m2=Matrix[[15,12,6,5],[12,8,10,8],[4,6,9,10]]
		assert_in_delta(0.349,RubySS::Correlation.gamma(m2),0.001)
		

	end
    def test_estimation_mean              
        v=([42]*23+[41]*4+[36]*1+[32]*1+[29]*1+[27]*2+[23]*1+[19]*1+[16]*2+[15]*2+[14,11,10,9,7]+ [6]*3+[5]*2+[4,3]).to_vector(:scale)
        assert_equal(50,v.size)
        assert_equal(1471,v.sum())
        limits=RubySS::SRS.mean_confidence_interval_z(v.mean(),v.sds(),v.size,676,0.80)
       
    end
    def test_estimation_proportion
        # total
        pop=3042
        sam=200
        prop=0.19
        assert_in_delta(81.8, RubySS::SRS.proportion_total_sd_ep_wor(prop, sam, pop), 0.1)
        
        # confidence limits
        pop=500
        sam=100
        prop=0.37
        a=0.95
        l= RubySS::SRS.proportion_confidence_interval_z(prop, sam, pop, a)
        assert_in_delta(0.28,l[0],0.01)
        assert_in_delta(0.46,l[1],0.01)
    end
    
end