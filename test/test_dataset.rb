require File.dirname(__FILE__)+'/../lib/rubyss'
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
        assert_equal(%w{id name age city a1}, @ds.fields)
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
	def test_vector_by_calculation
		a1=[1,2,3,4,5,6,7].to_vector(:scale)
		a2=[10,20,30,40,50,60,70].to_vector(:scale)
		a3=[100,200,300,400,500,600,700].to_vector(:scale)
		ds={'a1'=>a1,'a2'=>a2,'a3'=>a3}.to_dataset
		total=ds.vector_by_calculation() {|row|
			row['a1']+row['a2']+row['a3']
		}
		expected=[111,222,333,444,555,666,777].to_vector(:scale)
		assert_equal(expected,total)
	end
	def test_vector_sum
		a1=[1  ,2 ,3 ,4  , 5,nil].to_vector(:scale)
		a2=[10 ,10,20,20 ,20,30].to_vector(:scale)
		b1=[nil,1 ,1 ,1  ,1 ,2].to_vector(:scale)
		b2=[2  ,2 ,2 ,nil,2 ,3].to_vector(:scale)
		ds={'a1'=>a1,'a2'=>a2,'b1'=>b1,'b2'=>b2}.to_dataset
		total=ds.vector_sum
		a=ds.vector_sum(['a1','a2'])
		b=ds.vector_sum(['b1','b2'])
		expected_a=[11,12,23,24,25,nil].to_vector(:scale)
		expected_b=[nil,3,3,nil,3,5].to_vector(:scale)
		expected_total=[nil,15,26,nil,28,nil].to_vector(:scale)
		assert_equal(expected_a, a)
		assert_equal(expected_b, b)
		assert_equal(expected_total, total)
	end
    def test_vector_missing_values
        a1=[1  ,nil ,3 ,4  , 5,nil].to_vector(:scale)
		a2=[10 ,nil ,20,20 ,20,30].to_vector(:scale)
		b1=[nil,nil ,1 ,1  ,1 ,2].to_vector(:scale)
		b2=[2  ,2   ,2 ,nil,2 ,3].to_vector(:scale)
        c= [nil,2   , 4,2   ,2 ,2].to_vector(:scale)
		ds={'a1'=>a1,'a2'=>a2,'b1'=>b1,'b2'=>b2,'c'=>c}.to_dataset
        mva=[2,3,0,1,0,1].to_vector(:scale)
        assert_equal(mva,ds.vector_missing_values)
    end
    def test_vector_count_characters
        a1=[1  ,"abcde"  ,3  ,4  , 5,nil].to_vector(:scale)
		a2=[10 ,20.3     ,20 ,20 ,20,30].to_vector(:scale)
		b1=[nil,"343434" ,1  ,1  ,1 ,2].to_vector(:scale)
		b2=[2  ,2        ,2  ,nil,2 ,3].to_vector(:scale)
        c= [nil,2        ,"This is a nice example",2   ,2 ,2].to_vector(:scale)
		ds={'a1'=>a1,'a2'=>a2,'b1'=>b1,'b2'=>b2,'c'=>c}.to_dataset
        exp=[4,17,27,5,6,5].to_vector(:scale)
        assert_equal(exp,ds.vector_count_characters)
        
    end
    def test_vector_mean
		a1=[1  ,2 ,3 ,4  , 5,nil].to_vector(:scale)
		a2=[10 ,10,20,20 ,20,30].to_vector(:scale)
		b1=[nil,1 ,1 ,1  ,1 ,2].to_vector(:scale)
		b2=[2  ,2 ,2 ,nil,2 ,3].to_vector(:scale)
        c= [nil,2, 4,2   ,2 ,2].to_vector(:scale)
		ds={'a1'=>a1,'a2'=>a2,'b1'=>b1,'b2'=>b2,'c'=>c}.to_dataset
		total=ds.vector_mean
		a=ds.vector_mean(['a1','a2'],1)
		b=ds.vector_mean(['b1','b2'],1)
        c=ds.vector_mean(['b1','b2','c'],1)
		expected_a=[5.5,6,11.5,12,12.5,30].to_vector(:scale)
		expected_b=[2,1.5,1.5,1,1.5,2.5].to_vector(:scale)
		expected_c=[nil, 5.0/3,7.0/3,1.5,5.0/3,7.0/3].to_vector(:scale)
		expected_total=[nil,3.4,6,nil,6.0,nil].to_vector(:scale)
		assert_equal(expected_a, a)
		assert_equal(expected_b, b)
		assert_equal(expected_c, c)
		assert_equal(expected_total, total)
	end
    
    def test_each_array
        expected=[[1,'Alex',20,'New York','a,b'], [2,'Claude',23,'London','b,c'], [3,'Peter',25,'London','a'],[4,'Franz', 27,'Paris',nil],[5,'George',5,'Tome','a,b,c']]
        out=[]
        @ds.each_array{ |a|
            out.push(a)
        }
        assert_equal(expected,out)
    end
    def test_recode
        @ds['age'].type=:scale
        @ds.recode!("age") {|c| c['id']*2}
        expected=[2,4,6,8,10].to_vector(:scale)
        assert_equal(expected,@ds['age'])
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
    def test_split_by_separator_recode
        @ds.add_vectors_by_split_recode("a1","_")
        assert_equal(%w{id name age city a1 a1_1 a1_2 a1_3},@ds.fields)
        assert_equal([1,0,1,nil,1],@ds.col('a1_1').to_a)
        assert_equal([1,1,0,nil,1],@ds.col('a1_2').to_a)
        assert_equal([0,1,0,nil,1],@ds.col('a1_3').to_a)
        assert_equal({'a1_1'=>'a1:a', 'a1_2'=>'a1:b', 'a1_3'=>'a1:c'},@ds.labels)
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
    def test_range
        v1=[1,2,3,4].to_vector
        v2=[5,6,7,8].to_vector
        v3=[9,10,11,12].to_vector
        ds1=RubySS::Dataset.new({'v1'=>v1,'v2'=>v2,'v3'=>v3}, %w{v3 v2 v1})
        assert_same(v1,ds1['v1'])
        ds2=ds1["v2".."v1"]
        assert_equal(%w{v2 v1},ds2.fields)
        assert_same(ds1['v1'],ds2['v1'])
        assert_same(ds1['v2'],ds2['v2'])
        

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
        # dup partial
        ds3=ds1.dup('v1')
        ds_exp=RubySS::Dataset.new({'v1'=>v1},%w{v1})
        assert_equal(ds_exp,ds3)
        assert_not_same(ds_exp,ds3)
        assert_equal(ds3['v1'],ds_exp['v1'])
        assert_not_same(ds3['v1'],ds_exp['v1'])
        assert_equal(ds3.fields,ds_exp.fields)
        assert_not_same(ds3.fields,ds_exp.fields)
        
        
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
    def test_from_to
        assert_equal(%w{name age city}, @ds.from_to("name","city"))
        assert_raise ArgumentError do
            @ds.from_to("name","a2")
        end
    end
    def test_dup_only_valid
        v1=[1,nil,3,4].to_vector(:scale)
        v2=[5,6,nil,8].to_vector(:scale)
        v3=[9,10,11,12].to_vector(:scale)
        ds1=RubySS::Dataset.new({'v1'=>v1,'v2'=>v2,'v3'=>v3})
        ds2=ds1.dup_only_valid
        expected=RubySS::Dataset.new({'v1'=>[1,4].to_vector(:scale), 'v2'=> [5,8].to_vector(:scale), 'v3'=>[9, 12].to_vector(:scale)})
        assert_equal(expected,ds2)
		assert_equal(expected.vectors.values,RubySS::only_valid(v1,v2,v3))
    end
    def test_filter
        @ds['age'].type=:scale
        filtered=@ds.filter{|c| c['id']==2 or c['id']==4}
        expected=RubySS::Dataset.new({'id' => RubySS::Vector.new([2,4]), 'name'=>RubySS::Vector.new(%w{Claude Franz}), 'age'=>RubySS::Vector.new([23,27],:scale),
        'city'=>RubySS::Vector.new(['London','Paris']),
        'a1'=>RubySS::Vector.new(['b,c',nil,])}, ['id','name','age','city','a1'])
        assert_equal(expected,filtered)
    end                                  
	def test_filter_field
		@ds['age'].type=:scale
        filtered=@ds.filter_field('id') {|c| c['id']==2 or c['id']==4}
        expected=[2,4].to_vector
        assert_equal(expected,filtered)
		
	end
    def test_verify
        name=%w{r1 r2 r3 r4}.to_vector(:nominal)
        v1=[1,2,3,4].to_vector(:scale)
        v2=[4,3,2,1].to_vector(:scale)
        v3=[10,20,30,40].to_vector(:scale)
        v4=%w{a b a b}.to_vector(:nominal)
        ds={'v1'=>v1,'v2'=>v2,'v3'=>v3,'v4'=>v4,'id'=>name}.to_dataset
        ds.fields=%w{v1 v2 v3 v4 id}
        #Correct
        t1=create_test("If v4=a, v1 odd") {|r| r['v4']=='b' or (r['v4']=='a' and r['v1']%2==1)}
        t2=create_test("v3=v1*10")  {|r| r['v3']==r['v1']*10}
        # Fail!
        t3=create_test("v4='b'") {|r| r['v4']=='b'}
        exp1=["1 [1]: v4='b'", "3 [3]: v4='b'"]
        exp2=["1 [r1]: v4='b'", "3 [r3]: v4='b'"]
        res=ds.verify(t3,t1,t2)
        assert_equal(exp1,res)
        res=ds.verify('id',t1,t2,t3)
        assert_equal(exp2,res)

    end
end