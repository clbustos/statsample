require File.dirname(__FILE__)+'/../lib/rubyss'
require 'test/unit'

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

end