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
end