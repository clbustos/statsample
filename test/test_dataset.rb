require File.dirname(__FILE__)+'/../lib/rubyss.rb'
require 'rubyss/dataset'
require 'test/unit'

class RubySSCSVTestCase < Test::Unit::TestCase

	def initialize(*args)
        @ds=RubySS::CSV.read("test_csv.csv")
		super
	end
    def test_readfile
        assert_equal(5,@ds.cases)
        assert_equal(%w{id name age city a1},@ds.fields)
    end
    def test_add_vector
        v=RubySS::Vector.new(%w{a b c d e})
        @ds.add_vector('new',v)
        assert_equal(%w{id name age city a1 new},@ds.fields)
    end
    def test_delete_vector
        @ds.delete_vector('name')
        assert_equal(%w{id age city a1},@ds.fields)
        assert_equal(%w{a1 age city id},@ds.vectors.keys.sort)
    end
    def test_change_type
        @ds.col('age').type=:scale
        assert_equal(:scale,@ds.col('age').type)
    end
    def test_split_by_separator
        @ds.split_by_separator("a1")
        assert_equal(%w{id name age city a1 a1-a a1-b a1-c},@ds.fields)
        assert_equal([1,0,1,nil,1],@ds.col('a1-a').to_a)
        assert_equal([1,1,0,nil,1],@ds.col('a1-b').to_a)
        assert_equal([0,1,0,nil,1],@ds.col('a1-c').to_a)
    end
end