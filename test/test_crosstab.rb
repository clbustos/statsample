require File.dirname(__FILE__)+'/../lib/rubyss.rb'
require 'rubyss/crosstab'
require 'test/unit'

class RubySSCrosstabTestCase < Test::Unit::TestCase

	def initialize(*args)
		@v1=%w{black blonde black black red black brown black blonde black red black blonde}.to_vector
		@v2=%w{woman man man woman man man man woman man woman woman man man}.to_vector
		@ct=RubySS::Crosstab.new(@v1,@v2)
		super
	end
	def test_crosstab_errors
		e1=%w{black blonde black black red black brown black blonde black}
		assert_raise ArgumentError do
			RubySS::Crosstab.new(e1,@v2)
		end
		e2=%w{black blonde black black red black brown black blonde black black}.to_vector
		
		assert_raise ArgumentError do
			RubySS::Crosstab.new(e2,@v2)
		end
		assert_nothing_raised do
			RubySS::Crosstab.new(@v1,@v2)
		end
	end
	def test_crosstab_basic
		assert_equal(%w{black blonde brown red}, @ct.rows_names)
		assert_equal(%w{man woman}, @ct.cols_names)
		assert_equal({'black'=>7,'blonde'=>3,'red'=>2,'brown'=>1}, @ct.rows_total)
		assert_equal({'man'=>8,'woman'=>5}, @ct.cols_total)
	end
	def test_crosstab_frequencies
		p @ct.frequencies
	end
end
