require File.dirname(__FILE__)+'/../lib/rubyss.rb'
require 'rubyss/dataset'
require 'test/unit'

class RubySSStatisicsTestCase < Test::Unit::TestCase

	def initialize(*args)
		super
	end
    def test_chi_square
        assert_raise TypeError do
            RubySS.matrix_chi_square(1,1)
        end
        real=Matrix[[95,95],[45,155]]
        expected=Matrix[[68,122],[72,128]]
        assert_nothing_raised do
            chi=RubySS.matrix_chi_square(real,expected)
        end
        chi=RubySS.matrix_chi_square(real,expected)
        assert_in_delta(32.53,chi,0.1)
    end
end