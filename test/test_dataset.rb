require(File.dirname(__FILE__)+'/test_helpers.rb')

class StatsampleDatasetTestCase < MiniTest::Unit::TestCase
  def setup
    @ds=Statsample::Dataset.new({'id' => Statsample::Vector.new([1,2,3,4,5]), 'name'=>Statsample::Vector.new(%w{Alex Claude Peter Franz George}), 'age'=>Statsample::Vector.new([20,23,25,27,5]),
      'city'=>Statsample::Vector.new(['New York','London','London','Paris','Tome']),
    'a1'=>Statsample::Vector.new(['a,b','b,c','a',nil,'a,b,c'])}, ['id','name','age','city','a1'])
  end
  def test_basic
    assert_equal(5,@ds.cases)
    assert_equal(%w{id name age city a1}, @ds.fields)
  end
  def test_saveload
    outfile=Tempfile.new("dataset.ds")
    @ds.save(outfile.path)
    a=Statsample.load(outfile.path)
    assert_equal(@ds,a)
  end

  def test_matrix
    matrix=Matrix[[1,2],[3,4],[5,6]]
    ds=Statsample::Dataset.new('v1'=>[1,3,5].to_vector,'v2'=>[2,4,6].to_vector)
    assert_equal(matrix,ds.to_matrix)
  end

  def test_fields
    @ds.fields=%w{name a1 id age city}
    assert_equal(%w{name a1 id age city}, @ds.fields)
    @ds.fields=%w{id name age}
    assert_equal(%w{id name age a1 city}, @ds.fields)
  end
  def test_merge
    a=[1,2,3].to_scale
    b=[3,4,5].to_vector
    c=[4,5,6].to_scale
    d=[7,8,9].to_vector
    e=[10,20,30].to_vector
    ds1={'a'=>a,'b'=>b}.to_dataset
    ds2={'c'=>c,'d'=>d}.to_dataset
    exp={'a'=>a,'b'=>b,'c'=>c,'d'=>d}.to_dataset

    assert_equal(exp,ds1.merge(ds2))
    exp.fields=%w{c d a b}
    assert_equal(exp,ds2.merge(ds1))
    ds3={'a'=>e}.to_dataset
    exp={'a_1'=>a,'b'=>b,'a_2'=>e}.to_dataset
    exp.fields=%w{a_1 b a_2}
    assert_equal(exp,ds1.merge(ds3))
  end
  def test_each_vector
    a=[1,2,3].to_vector
    b=[3,4,5].to_vector
    fields=["a","b"]
    ds=Statsample::Dataset.new({'a'=>a,'b'=>b},fields)
    res=[]
    ds.each_vector{|k,v|
      res.push([k,v])
    }
    assert_equal([["a",a],["b",b]],res)
    ds.fields=["b","a"]
    res=[]
    ds.each_vector{|k,v|
      res.push([k,v])
    }
    assert_equal([["b",b],["a",a]],res)
  end
  def test_equality
    v1=[1,2,3,4].to_vector
    v2=[5,6,7,8].to_vector
    ds1=Statsample::Dataset.new({'v1'=>v1,'v2'=>v2}, %w{v2 v1})
    v3=[1,2,3,4].to_vector
    v4=[5,6,7,8].to_vector
    ds2=Statsample::Dataset.new({'v1'=>v3,'v2'=>v4}, %w{v2 v1})
    assert_equal(ds1,ds2)
    ds2.fields=%w{v1 v2}
    assert_not_equal(ds1,ds2)
  end
  def test_add_vector
    v=Statsample::Vector.new(%w{a b c d e})
    @ds.add_vector('new',v)
    assert_equal(%w{id name age city a1 new},@ds.fields)
    x=Statsample::Vector.new(%w{a b c d e f g})
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
    # Native methods
    assert_equal({'id'=>1,'name'=>'Alex','city'=>'New York','age'=>20,'a1'=>'a,b'},@ds._case_as_hash(0))
    assert_equal([5,'George',5,'Tome','a,b,c'],@ds._case_as_array(4))



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
    {'a1_1'=>'a1:a', 'a1_2'=>'a1:b', 'a1_3'=>'a1:c'}.each do |k,v|
      assert_equal(v, @ds[k].name)
    end
  end
  def test_split_by_separator
    @ds.add_vectors_by_split("a1","_")
    assert_equal(%w{id name age city a1 a1_a a1_b a1_c},@ds.fields)
    assert_equal([1,0,1,nil,1],@ds.col('a1_a').to_a)
    assert_equal([1,1,0,nil,1],@ds.col('a1_b').to_a)
    assert_equal([0,1,0,nil,1],@ds.col('a1_c').to_a)
  end
  def test_percentiles
    v1=(1..100).to_a.to_scale
    assert_equal(50.5,v1.median)
    assert_equal(25.5, v1.percentil(25))
    v2=(1..99).to_a.to_scale
    assert_equal(50,v2.median)
    assert_equal(25,v2.percentil(25))
    v3=(1..50).to_a.to_scale
    assert_equal(25.5, v3.median)
    assert_equal(13, v3.percentil(25))

  end
  def test_add_case
    ds=Statsample::Dataset.new({'a'=>[].to_vector, 'b'=>[].to_vector, 'c'=>[].to_vector})
    ds.add_case([1,2,3])
    ds.add_case({'a'=>4,'b'=>5,'c'=>6})
    ds.add_case([[7,8,9],%w{a b c}])
    assert_equal({'a'=>1,'b'=>2,'c'=>3},ds.case_as_hash(0))
    assert_equal([4,5,6],ds.case_as_array(1))
    assert_equal([7,8,9],ds.case_as_array(2))
    assert_equal(['a','b','c'],ds.case_as_array(3))
    ds.add_case_array([6,7,1])
    ds.update_valid_data
    assert_equal([6,7,1],ds.case_as_array(4))

  end
  def test_marshaling
    ds_marshal=Marshal.load(Marshal.dump(@ds))
    assert_equal(ds_marshal,@ds)
  end
  def test_range
    v1=[1,2,3,4].to_vector
    v2=[5,6,7,8].to_vector
    v3=[9,10,11,12].to_vector
    ds1=Statsample::Dataset.new({'v1'=>v1,'v2'=>v2,'v3'=>v3}, %w{v3 v2 v1})
    assert_same(v1,ds1['v1'])
    ds2=ds1["v2".."v1"]
    assert_equal(%w{v2 v1},ds2.fields)
    assert_same(ds1['v1'],ds2['v1'])
    assert_same(ds1['v2'],ds2['v2'])


  end
  def test_dup
    v1=[1,2,3,4].to_vector
    v2=[5,6,7,8].to_vector
    ds1=Statsample::Dataset.new({'v1'=>v1,'v2'=>v2}, %w{v2 v1})
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
    ds_exp=Statsample::Dataset.new({'v1'=>v1},%w{v1})
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
  def test_each_array_with_nils
    v1=[1,-99,3,4,"na"].to_vector(:scale,:missing_values=>[-99,"na"])
    v2=[5,6,-99,8,20].to_vector(:scale,:missing_values=>[-99])
    v3=[9,10,11,12,20].to_vector(:scale,:missing_values=>[-99])
    ds1=Statsample::Dataset.new({'v1'=>v1,'v2'=>v2,'v3'=>v3})
    ds2=ds1.dup_empty
    ds1.each_array_with_nils {|row|
      ds2.add_case_array(row)
    }
    ds2.update_valid_data
    assert_equal([1,nil,3,4,nil],ds2['v1'].data)
    assert_equal([5,6,nil,8,20],ds2['v2'].data)
  end
  def test_dup_only_valid
    v1=[1,nil,3,4].to_vector(:scale)
    v2=[5,6,nil,8].to_vector(:scale)
    v3=[9,10,11,12].to_vector(:scale)
    ds1=Statsample::Dataset.new({'v1'=>v1,'v2'=>v2,'v3'=>v3})
    ds2=ds1.dup_only_valid
    expected=Statsample::Dataset.new({'v1'=>[1,4].to_vector(:scale), 'v2'=> [5,8].to_vector(:scale), 'v3'=>[9, 12].to_vector(:scale)})
    assert_equal(expected,ds2)
    assert_equal(expected.vectors.values,Statsample::only_valid(v1,v2,v3))
  end
  def test_filter
    @ds['age'].type=:scale
    filtered=@ds.filter{|c| c['id']==2 or c['id']==4}
    expected=Statsample::Dataset.new({'id' => Statsample::Vector.new([2,4]), 'name'=>Statsample::Vector.new(%w{Claude Franz}), 'age'=>Statsample::Vector.new([23,27],:scale),
      'city'=>Statsample::Vector.new(['London','Paris']),
    'a1'=>Statsample::Vector.new(['b,c',nil,])}, ['id','name','age','city','a1'])
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
  def test_compute_operation
    v1=[1,2,3,4].to_vector(:scale)
    v2=[4,3,2,1].to_vector(:scale)
    v3=[10,20,30,40].to_vector(:scale)
    vscale=[1.quo(2),1,3.quo(2),2].to_vector(:scale)
    vsum=[1+4+10.0,2+3+20.0,3+2+30.0,4+1+40.0].to_vector(:scale)
    vmult=[1*4,2*3,3*2,4*1].to_vector(:scale)
    ds={'v1'=>v1,'v2'=>v2,'v3'=>v3}.to_dataset
    assert_equal(vscale,ds.compute("v1/2"))
    assert_equal(vsum,ds.compute("v1+v2+v3"))
    assert_equal(vmult,ds.compute("v1*v2"))

  end
  def test_crosstab_with_asignation
    v1=%w{a a a b b b c c c}.to_vector
    v2=%w{a b c a b c a b c}.to_vector
    v3=%w{0 1 0 0 1 1 0 0 1}.to_scale
    ds=Statsample::Dataset.crosstab_by_asignation(v1,v2,v3)
    assert_equal(:nominal, ds['_id'].type)
    assert_equal(:scale, ds['a'].type)
    assert_equal(:scale, ds['b'].type)
    ev_id=%w{a b c}.to_vector
    ev_a =%w{0 0 0}.to_scale
    ev_b =%w{1 1 0}.to_scale
    ev_c =%w{0 1 1}.to_scale
    ds2={'_id'=>ev_id, 'a'=>ev_a, 'b'=>ev_b, 'c'=>ev_c}.to_dataset
    assert_equal(ds, ds2)
  end
  def test_one_to_many
    cases=[
      ['1','george','red',10,'blue',20,nil,nil],
      ['2','fred','green',15,'orange',30,'white',20],
      ['3','alfred',nil,nil,nil,nil,nil,nil]
    ]
    ds=Statsample::Dataset.new(%w{id name car_color1 car_value1 car_color2 car_value2 car_color3 car_value3})
    cases.each {|c| ds.add_case_array c }
    ds.update_valid_data
    ids=%w{1 1 2 2 2}.to_vector
    colors=%w{red blue green orange white}.to_vector
    values=[10,20,15,30,20].to_vector
    col_ids=[1,2,1,2,3].to_scale
    ds_expected={'id'=>ids, '_col_id'=>col_ids, 'color'=>colors, 'value'=>values}.to_dataset(['id','_col_id', 'color','value'])
    assert_equal(ds_expected, ds.one_to_many(%w{id}, "car_%v%n"))

  end

end
