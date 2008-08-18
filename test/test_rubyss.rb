require '../lib/rubyss.rb'
require 'test/unit'

class RubySSColumnTestCase < Test::Unit::TestCase

	def initialize(*args)
		super
		@c = RubySS::Column.new([5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99], :scale)
		@c.missing_values=[-99]
	end
	def test_missing_values
		@c.missing_values=[10]
		assert_equal(@c.valid_data.sort,[-99,-99,1,2,3,4,5,5,5,5,5,6,6,7,8,9])
		@c.missing_values=[-99]
		assert_equal(@c.valid_data.sort,[1,2,3,4,5,5,5,5,5,6,6,7,8,9,10])
		@c.missing_values=[]
		assert_equal(@c.valid_data.sort,[-99,-99,1,2,3,4,5,5,5,5,5,6,6,7,8,9,10])
	end
	def test_types
		@c.type=:nominal
		assert_raise NoMethodError do
			@c.median
		end
		@c.type=:ordinal
		assert_raise NoMethodError do
			@c.mean
		end
	end
	def test_nominal
		assert_equal(@c[1],5)
		assert_equal(@c.frequencies,{1=>1,2=>1,3=>1,4=>1,5=>5,6=>2,7=>1,8=>1, 9=>1,10=>1})
		assert_equal(@c.factors.sort,[1,2,3,4,5,6,7,8,9,10])
		assert_equal(@c.mode,5)
		assert_equal(@c.n,15)
	end
	def test_ordinal
		assert_equal(@c.median,5)
	end
end