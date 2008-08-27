require File.dirname(__FILE__)+'/../lib/rubyss.rb'
require 'test/unit'

class RubySSVectorTestCase < Test::Unit::TestCase

	def initialize(*args)
		super
		@c = RubySS::Vector.new([5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99], :nominal)
		@c.missing_values=[-99]
	end
    def test_enumerable
        val=@c.collect {|v| v}
        assert_equal(val,[5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99])
    end
	def test_missing_values
		@c.missing_values=[10]
		assert_equal(@c.valid_data.sort,[-99,-99,1,2,3,4,5,5,5,5,5,6,6,7,8,9])
		@c.missing_values=[-99]
		assert_equal(@c.valid_data.sort,[1,2,3,4,5,5,5,5,5,6,6,7,8,9,10])
		@c.missing_values=[]
		assert_equal(@c.valid_data.sort,[-99,-99,1,2,3,4,5,5,5,5,5,6,6,7,8,9,10])
	end
    def test_labeled
        @c.labels={5=>'FIVE'}
        assert_equal(["FIVE","FIVE","FIVE","FIVE","FIVE",6,6,7,8,9,10,1,2,3,4,nil,-99, -99],@c.vector_labeled.to_a)
    end
    def test_split_by_separator
        a = RubySS::Vector.new(["a","a,b","c,d","a,d",10,nil],:nominal)
        b=a.split_by_separator(",")
        assert_kind_of(Hash, b)
        assert_instance_of(RubySS::Vector,b['a'])
        assert_instance_of(RubySS::Vector,b['b'])
        assert_instance_of(RubySS::Vector,b['c'])
        assert_instance_of(RubySS::Vector,b['d'])
        assert_instance_of(RubySS::Vector,b[10])
        assert_equal([1,1,0,1,0,nil],b['a'].to_a)
        assert_equal([0,1,0,0,0,nil],b['b'].to_a)
        assert_equal([0,0,1,0,0,nil],b['c'].to_a)
        assert_equal([0,0,1,1,0,nil],b['d'].to_a)
        assert_equal([0,0,0,0,1,nil],b[10].to_a)
        
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
		assert_equal({ 1=>1,2=>1,3=>1,4=>1,5=>5,6=>2,7=>1,8=>1, 9=>1,10=>1},@c.frequencies)
		assert_equal({ 1 => 1.to_f/15 ,2=>1.to_f/15, 3=>1.to_f/15,4=>1.to_f/15,5=>5.to_f/15,6=>2.to_f/15,7=>1.to_f/15,8=>1.to_f/15, 9=>1.to_f/15,10=>1.to_f/15}, @c.proportions)
		assert_equal(@c.factors.sort,[1,2,3,4,5,6,7,8,9,10])
		assert_equal(@c.mode,5)
		assert_equal(@c.n_valid,15)
	end
	def test_ordinal
        @c.type=:ordinal
		assert_equal(5,@c.median)
		assert_equal(4,@c.percentil(25))
		assert_equal(7,@c.percentil(75))
	end
    def test_scale
        a=RubySS::Vector.new([1,2,3,4,"STRING"], :scale)
        assert_equal(10,a.sum)
    end
    def test_summary
        @c.type=:nominal
        assert_match(/Distribution/, @c.summary())
        @c.type=:ordinal
        assert_match(/median/, @c.summary())
        @c.type=:scale
        assert_match(/mean/, @c.summary())
    end
    def test_add
        a=RubySS::Vector.new([1,2,3,4,5], :scale)
        b=RubySS::Vector.new([11,12,13,14,15], :scale)
        assert_equal([3,4,5,6,7], (a+2).to_a)
        assert_equal([12,14,16,18,20], (a+b).to_a)
        assert_raise  ArgumentError do
			a+@c
		end
        assert_raise  TypeError do
			a+"string"
		end
        a=RubySS::Vector.new([nil,1, 2  ,3 ,4 ,5], :scale)
        b=RubySS::Vector.new([11, 12,nil,13,14,15], :scale)
        assert_equal([nil,13,nil,16,18,20], (a+b).to_a)
        assert_equal([nil,13,nil,16,18,20], (a+b.to_a).to_a)
    end
    def test_minus
        a=RubySS::Vector.new([1,2,3,4,5], :scale)
        b=RubySS::Vector.new([11,12,13,14,15], :scale)
        assert_equal([-1,0,1,2,3], (a-2).to_a)
        assert_equal([10,10,10,10,10], (b-a).to_a)
        assert_raise  ArgumentError do
			a-@c
		end
        assert_raise  TypeError do
			a-"string"
		end
        a=RubySS::Vector.new([nil,1, 2  ,3 ,4 ,5], :scale)
        b=RubySS::Vector.new([11, 12,nil,13,14,15], :scale)
        assert_equal([nil,11,nil,10,10,10], (b-a).to_a)
        assert_equal([nil,11,nil,10,10,10], (b-a.to_a).to_a)
    end
    def test_samples
        srand(1)
        assert_equal(100,@c.sample_with_replacement(100).size)
        assert_equal(@c.valid_data.to_a.sort,@c.sample_without_replacement(15).sort)
        assert_raise  ArgumentError do
			@c.sample_without_replacement(20)
		end
    end
    
    def test_gsl
		if HAS_GSL
			a=RubySS::Vector.new([1,2,3,4,"STRING"], :scale)
			assert_equal(2,a.mean)
			assert_equal(a.slow_variance_sample,a.variance_sample)
			assert_equal(a.slow_sds,a.sds)
			a=[1,2,3,4].to_vector
			b=[4,3,2,1].to_vector
			a.type=:scale
			b.type=:scale
			assert_equal(-1,a.correlation(b))
		end
	end
	def test_vector_matrix
		v1=%w{a a a b b b c c}.to_vector
		v2=%w{1 3 4 5 6 4 3 2}.to_vector
		v3=%w{1 0 0 0 1 1 1 0}.to_vector
		ex=Matrix.rows([["a", "1", "1"], ["a", "3", "0"], ["a", "4", "0"], ["b", "5", "0"], ["b", "6", "1"], ["b", "4", "1"], ["c", "3", "1"], ["c", "2", "0"]])
		assert_equal(ex,RubySS.vector_cols_matrix(v1,v2,v3))
	end
end
