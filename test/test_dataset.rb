require File.dirname(__FILE__)+'/../lib/rubyss.rb'
require 'rubyss/dataset'
require 'test/unit'

class RubySSDatasetTestCase < Test::Unit::TestCase
	def initialize(*args)
        @ds=RubySS::Dataset.new({'id' => RubySS::Vector.new([1,2,3,4,5]), 'name'=>RubySS::Vector.new(%w{Alex Claude Peter Franz George}), 'age'=>RubySS::Vector.new([20,23,25,27,5]),
        'city'=>RubySS::Vector.new(['New York','London','London','Paris','Tome']),
        'a1'=>RubySS::Vector.new(['a,b','b,c','a',nil,'a,b,c'])}, ['id','name','age','city','a1'])
		super
	end
    def test_basic
        assert_equal(5,@ds.cases)
        assert_equal(%w{id name age city a1},@ds.fields)
    end
    def test_matrix
        matrix=Matrix[[1,2],[3,4],[5,6]]
        ds=RubySS::Dataset.new('v1'=>[1,3,5].to_vector,'v2'=>[2,4,6].to_vector)
        assert_equal(matrix,ds.to_matrix)
    end        
    def test_fields
        @ds.fields=%w{name a1 id age city}
        assert_equal(%w{name a1 id age city}, @ds.fields)
        @ds.fields=%w{id name age}
        assert_equal(%w{id name age a1 city}, @ds.fields)
        
    end
    def test_equality
        v1=[1,2,3,4].to_vector
        v2=[5,6,7,8].to_vector
        ds1=RubySS::Dataset.new({'v1'=>v1,'v2'=>v2}, %w{v2 v1})
        v3=[1,2,3,4].to_vector
        v4=[5,6,7,8].to_vector
        ds2=RubySS::Dataset.new({'v1'=>v3,'v2'=>v4}, %w{v2 v1})
        assert_equal(ds1,ds2)
        ds2.fields=%w{v1 v2}
        assert_not_equal(ds1,ds2)
    end
    def test_add_vector
        v=RubySS::Vector.new(%w{a b c d e})
        @ds.add_vector('new',v)
        assert_equal(%w{id name age city a1 new},@ds.fields)
        x=RubySS::Vector.new(%w{a b c d e f g})
        assert_raise ArgumentError do 
            @ds.add_vector('new2',x)
        end
    end
    def test_each_array
        expected=[[1,'Alex',20,'New York','a,b'], [2,'Claude',23,'London','b,c'], [3,'Peter',25,'London','a'],[4,'Franz', 27,'Paris',nil],[5,'George',5,'Tome','a,b,c']]
        out=[]
        @ds.each_array{ |a|
            out.push(a)
        }
        assert_equal(expected,out)
    end
    def test_case_as
        assert_equal({'id'=>1,'name'=>'Alex','city'=>'New York','age'=>20,'a1'=>'a,b'},@ds.case_as_hash(0))
        assert_equal([5,'George',5,'Tome','a,b,c'],@ds.case_as_array(4))

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
        @ds.add_vectors_by_split("a1","_")
        assert_equal(%w{id name age city a1 a1_a a1_b a1_c},@ds.fields)
        assert_equal([1,0,1,nil,1],@ds.col('a1_a').to_a)
        assert_equal([1,1,0,nil,1],@ds.col('a1_b').to_a)
        assert_equal([0,1,0,nil,1],@ds.col('a1_c').to_a)
    end
    def test_add_case
        ds=RubySS::Dataset.new({'a'=>[].to_vector, 'b'=>[].to_vector, 'c'=>[].to_vector})
        ds.add_case([1,2,3])
        ds.add_case({'a'=>4,'b'=>5,'c'=>6})
        ds.add_case([[7,8,9],%w{a b c}])
        assert_equal({'a'=>1,'b'=>2,'c'=>3},ds.case_as_hash(0))
        assert_equal([4,5,6],ds.case_as_array(1))
        assert_equal([7,8,9],ds.case_as_array(2))
        assert_equal(['a','b','c'],ds.case_as_array(3))
    end
    def test_marshaling
        ds_marshal=Marshal.load(Marshal.dump(@ds))
        assert_equal(ds_marshal,@ds)
    end
    def test_dup
        v1=[1,2,3,4].to_vector
        v2=[5,6,7,8].to_vector
        ds1=RubySS::Dataset.new({'v1'=>v1,'v2'=>v2}, %w{v2 v1})
        ds2=ds1.dup
        assert_equal(ds1,ds2)
        assert_not_same(ds1,ds2)
        assert_equal(ds1['v1'],ds2['v1'])
        assert_not_same(ds1['v1'],ds2['v1'])
        assert_equal(ds1.fields,ds2.fields)
        assert_not_same(ds1.fields,ds2.fields)
        ds1['v1'].type=:scale
        # empty
        ds3=ds1.dup_empty
        assert_not_equal(ds1,ds3)
        assert_not_equal(ds1['v1'],ds3['v1'])
        assert_equal([],ds3['v1'].data)
        assert_equal([],ds3['v2'].data)
        assert_equal(:scale,ds3['v1'].type)
        assert_equal(ds1.fields,ds2.fields)
        assert_not_same(ds1.fields,ds2.fields)
    end
    def test_dup_only_valid
        v1=[1,nil,3,4].to_vector(:scale)
        v2=[5,6,nil,8].to_vector(:scale)
        v3=[9,10,11,12].to_vector(:scale)
        ds1=RubySS::Dataset.new({'v1'=>v1,'v2'=>v2,'v3'=>v3})
        ds2=ds1.dup_only_valid
        expected=RubySS::Dataset.new({'v1'=>[1,4].to_vector(:scale), 'v2'=> [5,8].to_vector(:scale), 'v3'=>[9, 12].to_vector(:scale)})
        assert_equal(expected,ds2)
    end
end