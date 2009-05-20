require File.dirname(__FILE__)+'/../lib/rubyss'
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
    def test_split
        a = RubySS::Vector.new(["a","a,b","c,d","a,d","d",10,nil],:nominal)
        assert_equal([%w{a},%w{a b},%w{c d},%w{a d},%w{d},[10],nil], a.splitted)
    end
    def test_verify
        h=@c.verify{|d| !d.nil? and d>0}
        e={15=>nil,16=>-99,17=>-99}
        assert_equal(e,h)
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
        assert_equal({'a'=>3,'b'=>1,'c'=>1,'d'=>2,10=>1}, a.split_by_separator_freq())

        a = RubySS::Vector.new(["a","a*b","c*d","a*d",10,nil],:nominal)
        b=a.split_by_separator("*")
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
        assert_equal(@c.proportion, 1.to_f/15)
        assert_equal(@c.proportion(2), 1.to_f/15)
		assert_equal([1,2,3,4,5,6,7,8,9,10], @c.factors.sort)
		assert_equal(@c.mode,5)
		assert_equal(@c.n_valid,15)
	end
    def test_equality
        v1=[1,2,3].to_vector
        v2=[1,2,3].to_vector
        assert_equal(v1,v2)
        v1=[1,2,3].to_vector(:nominal)
        v2=[1,2,3].to_vector(:ordinal)
        assert_not_equal(v1,v2)
        v1=[1,2,3].to_vector()
        v2=[1,2,3].to_vector()
        assert_equal(v1,v2)
    end
	def test_ordinal
        @c.type=:ordinal
		assert_equal(5,@c.median)
		assert_equal(4,@c.percentil(25))
		assert_equal(7,@c.percentil(75))
	end
	def test_ranked
		v1=[0.8,1.2,1.2,2.3,18].to_vector(:ordinal)
		expected=[1,2.5,2.5,4,5].to_vector(:ordinal)
		assert_equal(expected,v1.ranked)
	end
    def test_scale
        a=RubySS::Vector.new([1,2,3,4,"STRING"], :scale)
        assert_equal(10,a.sum)
        i=0
        factors=a.factors.sort
        [0.0,1,2,3,4].each{|v|
            assert(v==factors[i])
            assert(v.class==factors[i].class,"#{v} - #{v.class} != #{factors[i]} - #{factors[i].class}")
            i+=1
        }
    end
    def test_vector_standarized
        v1=[1,2,3,4,nil].to_vector(:scale)
        sds=v1.sds
        expected=[((1-2.5) / sds),((2-2.5) / sds),((3-2.5) / sds),((4-2.5) / sds),nil].to_vector(:scale)
        vs=v1.vector_standarized
        assert_equal(expected, vs)
        assert_equal(0,vs.mean)
        assert_equal(1,vs.sds)
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
	def test_sum_of_squares
		a=[1,2,3,4,5,6].to_vector(:scale)
		assert_equal(17.5, a.sum_of_squared_deviation)
	end
    def test_samples
        srand(1)
        assert_equal(100,@c.sample_with_replacement(100).size)
        assert_equal(@c.valid_data.to_a.sort,@c.sample_without_replacement(15).sort)
        assert_raise  ArgumentError do
			@c.sample_without_replacement(20)
		end
        @c.type=:scale
        srand(1)
        assert_equal(100,@c.sample_with_replacement(100).size)
        assert_equal(@c.valid_data.to_a.sort,@c.sample_without_replacement(15).sort)
        
    end
    
    def test_gsl
		if HAS_GSL
			a=RubySS::Vector.new([1,2,3,4,"STRING"], :scale)
			assert_equal(2,a.mean)
			assert_equal(a.variance_sample_slow,a.variance_sample)
			assert_equal(a.standard_deviation_sample_slow,a.sds)
			assert_equal(a.variance_population_slow,a.variance_population)
			assert_equal(a.standard_deviation_population_slow,a.standard_deviation_population)

            assert_nothing_raised do
                a=[].to_vector(:scale)
            end
            a.add(1,false)
            a.add(2,false)
            a.set_valid_data
            assert_equal(3,a.sum)
            b=[1,2,nil,3,4,5,nil,6].to_vector(:scale)
            assert_equal(21,b.sum)
            assert_equal(3.5,b.mean)
            assert_equal(6,b.gsl.size)
            # histogram
            a=[11,12,13,15,21,22,23,32,33].to_vector(:scale)
            h=a.histogram(3)
            assert_equal(4,h[0])
            assert_equal(3,h[1])
            assert_equal(2,h[2])
            h=a.histogram([10,20,30,40])
            assert_equal(4,h[0])
            assert_equal(3,h[1])
            assert_equal(2,h[2])
            
		end
	end
	def test_vector_matrix        
		v1=%w{a a a b b b c c}.to_vector
		v2=%w{1 3 4 5 6 4 3 2}.to_vector
		v3=%w{1 0 0 0 1 1 1 0}.to_vector
		ex=Matrix.rows([["a", "1", "1"], ["a", "3", "0"], ["a", "4", "0"], ["b", "5", "0"], ["b", "6", "1"], ["b", "4", "1"], ["c", "3", "1"], ["c", "2", "0"]])
		assert_equal(ex,RubySS.vector_cols_matrix(v1,v2,v3))
	end
    def test_marshalling
        v1=(0..100).to_a.collect{|n| rand(100)}.to_vector(:scale)
        v2=Marshal.load(Marshal.dump(v1))
        assert_equal(v1,v2)
    end
    def test_dup
        v1=%w{a a a b b b c c}.to_vector
        v2=v1.dup
        assert_equal(v1.data,v2.data)
        assert_not_same(v1.data,v2.data)
        assert_equal(v1.type,v2.type)
        
        v1.type=:ordinal
        assert_not_equal(v1.type,v2.type)
        assert_equal(v1.missing_values,v2.missing_values)
        assert_not_same(v1.missing_values,v2.missing_values)
        assert_equal(v1.labels,v2.labels)
        assert_not_same(v1.labels,v2.labels)
        
        v3=v1.dup_empty
        assert_equal([],v3.data)
        assert_not_equal(v1.data,v3.data)
        assert_not_same(v1.data,v3.data)
        assert_equal(v1.type,v3.type)
        v1.type=:ordinal
        v3.type=:nominal
        assert_not_equal(v1.type,v3.type)
        assert_equal(v1.missing_values,v3.missing_values)
        assert_not_same(v1.missing_values,v3.missing_values)
        assert_equal(v1.labels,v3.labels)
        assert_not_same(v1.labels,v3.labels)
    end
     
end
