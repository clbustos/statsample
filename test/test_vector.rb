require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))

class StatsampleTestVector < MiniTest::Unit::TestCase
  def setup
    @c = Statsample::Vector.new([5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99], :nominal)
    @c.name="Test Vector"
    @c.missing_values=[-99]
  end
  def assert_counting_tokens(b)
    assert_equal([1,1,0,1,0,nil],b['a'].to_a)
    assert_equal([0,1,0,0,0,nil],b['b'].to_a)
    assert_equal([0,0,1,0,0,nil],b['c'].to_a)
    assert_equal([0,0,1,1,0,nil],b['d'].to_a)
    assert_equal([0,0,0,0,1,nil],b[10].to_a)
  end
  context Statsample do
    setup do
      @sample=100
      @a=@sample.times.map{|i| (i+rand(10)) %10 ==0 ? nil : rand(100)}.to_scale
      @b=@sample.times.map{|i| (i+rand(10)) %10 ==0 ? nil : rand(100)}.to_scale
      @correct_a=Array.new
      @correct_b=Array.new
      @a.each_with_index do |v,i|
        if !@a[i].nil? and !@b[i].nil?
          @correct_a.push(@a[i])
          @correct_b.push(@b[i])
        end
      end
      @correct_a=@correct_a.to_scale
      @correct_b=@correct_b.to_scale
      
      @common=lambda  do |av,bv|
        assert_equal(@correct_a, av, "A no es esperado")
        assert_equal(@correct_b, bv, "B no es esperado")
        assert(!av.has_missing_data?, "A tiene datos faltantes")
        assert(!bv.has_missing_data?, "b tiene datos faltantes")        
      end
    end
    should "return correct only_valid" do
      av,bv=Statsample.only_valid @a,@b
      av2,bv2=Statsample.only_valid av,bv
      @common.call(av,bv)
      assert_equal(av,av2)
      assert_not_same(av,av2)
      assert_not_same(bv,bv2)
    end
    should "return correct only_valid_clone" do
      av,bv=Statsample.only_valid_clone @a,@b
      @common.call(av,bv)
      av2,bv2=Statsample.only_valid_clone av,bv
      assert_equal(av,av2)
      assert_same(av,av2)
      assert_same(bv,bv2)
    end
    
  end
  context Statsample::Vector do
    setup do 
      @c = Statsample::Vector.new([5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99], :nominal)
      @c.name="Test Vector"
      @c.missing_values=[-99]
    end
    context "using matrix operations" do
      setup do
        @a=[1,2,3,4,5].to_scale
      end
      should "to_matrix returns a matrix with 1 row" do 
        mh=Matrix[[1,2,3,4,5]]
        assert_equal(mh,@a.to_matrix)
      end
      should "to_matrix(:vertical) returns a matrix with 1 column" do 
        mv=Matrix.columns([[1,2,3,4,5]])
        assert_equal(mv,@a.to_matrix(:vertical))
      end
      should "returns valid submatrixes" do
        # 3*4 + 2*5 = 22
        a=[3,2].to_vector(:scale)
        b=[4,5].to_vector(:scale)
        assert_equal(22,(a.to_matrix*b.to_matrix(:vertical))[0,0])
      end
    end
    context "when initializing" do
      setup do 
        @data=(10.times.map{rand(100)})+[nil]
        @original=Statsample::Vector.new(@data, :scale)
      end
      should "be the sample using []" do
        second=Statsample::Vector[*@data]
        assert_equal(@original, second)
      end
      should "[] returns same results as R-c()" do
        reference=[0,4,5,6,10].to_scale
        assert_equal(reference, Statsample::Vector[0,4,5,6,10])
        assert_equal(reference, Statsample::Vector[0,4..6,10])
        assert_equal(reference, Statsample::Vector[[0],[4,5,6],[10]])
        assert_equal(reference, Statsample::Vector[[0],[4,[5,[6]]],[10]])
        
        assert_equal(reference, Statsample::Vector[[0],[4,5,6].to_vector,[10]])
        
      end
      should "be the same usign #to_vector" do
        lazy1=@data.to_vector(:scale)
        assert_equal(@original,lazy1)
      end
      should "be the same using #to_scale" do
        lazy2=@data.to_scale
        assert_equal(@original,lazy2)
        assert_equal(:scale,lazy2.type)
        assert_equal(@data.find_all{|v| !v.nil?},lazy2.valid_data)
      end
      should "could use new_scale with size only" do
        v1=10.times.map {nil}.to_scale
        v2=Statsample::Vector.new_scale(10)
        assert_equal(v1,v2)
        
      end
      should "could use new_scale with size and value" do
        a=rand
        v1=10.times.map {a}.to_scale
        v2=Statsample::Vector.new_scale(10,a)
        assert_equal(v1,v2)
      end
      should "could use new_scale with func" do
        v1=10.times.map {|i| i*2}.to_scale
        v2=Statsample::Vector.new_scale(10) {|i| i*2}
        assert_equal(v1,v2)
      end
      
    end
    
    context "#split_by_separator" do
     
      setup do
        @a = Statsample::Vector.new(["a","a,b","c,d","a,d",10,nil],:nominal)
        @b=@a.split_by_separator(",")
      end
      should "returns a Hash" do
        assert_kind_of(Hash, @b)
      end
      should "return a Hash with keys with different values of @a" do
        expected=['a','b','c','d',10]
        assert_equal(expected, @b.keys)
      end
      
      should "returns a Hash, which values are Statsample::Vector" do
        @b.each_key {|k| assert_instance_of(Statsample::Vector, @b[k])}
      end
      should "hash values are n times the tokens appears" do
        assert_counting_tokens(@b)
      end
      should "#split_by_separator_freq returns the number of ocurrences of tokens" do 
        assert_equal({'a'=>3,'b'=>1,'c'=>1,'d'=>2,10=>1}, @a.split_by_separator_freq())
      end
      should "using a different separator give the same values" do
        a = Statsample::Vector.new(["a","a*b","c*d","a*d",10,nil],:nominal)
        b=a.split_by_separator("*")
        assert_counting_tokens(b)
      end
    end

    should "return correct histogram" do
      a=10.times.map {|v| v}.to_scale
      hist=a.histogram(2)
      assert_equal([5,5], hist.bin)
      3.times do |i|
        assert_in_delta(i*4.5, hist.get_range(i)[0], 1e-9)
      end
      
    end
    should "have a name" do
      @c.name=="Test Vector"
    end
    should "without explicit name, returns vector with succesive numbers" do
      a=10.times.map{rand(100)}.to_scale
      b=10.times.map{rand(100)}.to_scale
      assert_match(/Vector \d+/, a.name)
      a.name=~/Vector (\d+)/
      next_number=$1.to_i+1
      assert_equal("Vector #{next_number}",b.name)
    end
    should "save to a file and load the same Vector" do 
      outfile=Tempfile.new("vector.vec")
      @c.save(outfile.path)
      a=Statsample.load(outfile.path)
      assert_equal(@c,a)  
    end
    should "#collect returns an array" do
      val=@c.collect {|v| v}
      assert_equal(val,[5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99])
    end
    
    should "#recode returns a recoded array" do
      a=@c.recode{|v| @c.is_valid?(v) ? 0 : 1 }
      exp=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1].to_vector
      assert_equal(exp,a)
      exp.recode!{|v| v==0 ? 1:0}
      exp2=(([1]*15)+([0]*3)).to_vector
      assert_equal(exp2,exp)
    end
    should "#product returns the * of all values" do
      a=[1,2,3,4,5].to_vector(:scale)
      assert_equal(120,a.product)
    end
    
    should "missing values" do 
      @c.missing_values=[10]
      assert_equal([-99,-99,1,2,3,4,5,5,5,5,5,6,6,7,8,9], @c.valid_data.sort)
      assert_equal([5,5,5,5,5,6,6,7,8,9,nil,1,2,3,4,nil,-99,-99], @c.data_with_nils)
      @c.missing_values=[-99]
      assert_equal(@c.valid_data.sort,[1,2,3,4,5,5,5,5,5,6,6,7,8,9,10])
      assert_equal(@c.data_with_nils,[5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,nil,nil])
      @c.missing_values=[]
      assert_equal(@c.valid_data.sort,[-99,-99,1,2,3,4,5,5,5,5,5,6,6,7,8,9,10])
      assert_equal(@c.data_with_nils,[5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99])
      
    end
    should "correct has_missing_data? with missing data" do 
      a=[1,2,3,nil].to_vector
      assert(a.has_missing_data?)
    end
    should "correct has_missing_data? without missing data" do   
      a=[1,2,3,4,10].to_vector
      assert(!a.has_missing_data?)
    end
    should "with explicit missing_values, should respond has_missing_data?" do
      a=[1,2,3,4,10].to_vector
      a.missing_values=[10]
      assert(a.has_missing_data?)
    end 
    should "label correctly fields" do 
      @c.labels={5=>'FIVE'}
      assert_equal(["FIVE","FIVE","FIVE","FIVE","FIVE",6,6,7,8,9,10,1,2,3,4,nil,-99, -99],@c.vector_labeled.to_a)
    end
    should "verify" do 
      h=@c.verify{|d| !d.nil? and d>0}
      e={15=>nil,16=>-99,17=>-99}
      assert_equal(e,h)
    end
    should "have a summary with name on it" do
      assert_match(/#{@c.name}/, @c.summary)
    end
    should "split correctly" do
      a = Statsample::Vector.new(["a","a,b","c,d","a,d","d",10,nil],:nominal)
      assert_equal([%w{a},%w{a b},%w{c d},%w{a d},%w{d},[10],nil], a.splitted)      
    end
    should "multiply correct for scalar" do
      a = [1,2,3].to_scale
      assert_equal([5,10,15].to_scale, a*5)
    end
    should "multiply correct with other vector" do
      a = [1,2,3].to_scale
      b = [2,4,6].to_scale
      
      assert_equal([2,8,18].to_scale, a*b)
    end
    should "sum correct for scalar" do
      a = [1,2,3].to_scale
      assert_equal([11,12,13].to_scale, a+10)
    end
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
    assert_equal({ 1=>1,2=>1,3=>1,4=>1,5=>5,6=>2,7=>1,8=>1, 9=>1,10=>1},@c._frequencies)
    assert_equal({ 1 => 1.quo(15) ,2=>1.quo(15), 3=>1.quo(15),4=>1.quo(15),5=>5.quo(15),6=>2.quo(15),7=>1.quo(15), 8=>1.quo(15), 9=>1.quo(15),10=>1.quo(15)}, @c.proportions)
    assert_equal(@c.proportion, 1.quo(15))
    assert_equal(@c.proportion(2), 1.quo(15))
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
  def test_vector_percentil
    a=[1,2,2,3,4,5,5,5,6,10].to_scale
    expected=[10,25,25,40,50,70,70,70,90,100].to_scale
    assert_equal(expected, a.vector_percentil)
    a=[1,nil,nil,2,2,3,4,nil,nil,5,5,5,6,10].to_scale
    expected=[10,nil,nil,25,25,40,50,nil,nil,70,70,70,90,100].to_scale
    assert_equal(expected, a.vector_percentil)
    
    
  end
  def test_ordinal
    @c.type=:ordinal
    assert_equal(5,@c.median)
    assert_equal(4,@c.percentil(25))
    assert_equal(7,@c.percentil(75))

    v=[200000, 200000, 210000, 220000, 230000, 250000, 250000, 250000, 270000, 300000, 450000, 130000, 140000, 140000, 140000, 145000, 148000, 165000, 170000, 180000, 180000, 180000, 180000, 180000, 180000 ].to_scale
    assert_equal(180000,v.median)
    a=[7.0, 7.0, 7.0, 7.0, 7.0, 8.0, 8.0, 8.0, 9.0, 9.0, 10.0, 10.0, 10.0, 10.0, 10.0, 12.0, 12.0, 13.0, 14.0, 14.0, 2.0, 3.0, 3.0, 3.0, 3.0, 4.0, 4.0, 4.0, 4.0, 4.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 5.0, 6.0, 6.0, 6.0].to_scale
    assert_equal(4.5, a.percentil(25))
    assert_equal(6.5, a.percentil(50))
    assert_equal(9.5, a.percentil(75))
    assert_equal(3.0, a.percentil(10))
  end
  def test_ranked
    v1=[0.8,1.2,1.2,2.3,18].to_vector(:ordinal)
    expected=[1,2.5,2.5,4,5].to_vector(:ordinal)
    assert_equal(expected,v1.ranked)
    v1=[nil,0.8,1.2,1.2,2.3,18,nil].to_vector(:ordinal)
    expected=[nil,1,2.5,2.5,4,5,nil].to_vector(:ordinal)
    assert_equal(expected,v1.ranked)
  end
  def test_scale
    a=Statsample::Vector.new([1,2,3,4,"STRING"], :scale)
    assert_equal(10, a.sum)
    i=0
    factors=a.factors.sort
    [0,1,2,3,4].each{|v|
      assert(v==factors[i])
      assert(v.class==factors[i].class,"#{v} - #{v.class} != #{factors[i]} - #{factors[i].class}")
      i+=1
    }
  end
  def test_vector_centered
    mean=rand()
    samples=11
    centered=samples.times.map {|i| i-((samples/2).floor).to_i}.to_scale
    not_centered=centered.recode {|v| v+mean}
    obs=not_centered.centered
    centered.each_with_index do |v,i|
      assert_in_delta(v,obs[i],0.0001)
    end
  end
  def test_vector_standarized
    v1=[1,2,3,4,nil].to_vector(:scale)
    sds=v1.sds
    expected=[((1-2.5).quo(sds)),((2-2.5).quo(sds)),((3-2.5).quo(sds)),((4-2.5).quo(sds)), nil].to_vector(:scale)
    vs=v1.vector_standarized
    assert_equal(expected, vs)
    assert_equal(0,vs.mean)
    assert_equal(1,vs.sds)
  end
  def test_vector_standarized_with_zero_variance
    v1=100.times.map {|i| 1}.to_scale
    exp=100.times.map {nil}.to_scale
    assert_equal(exp,v1.standarized)
  end

    def test_check_type
    v=Statsample::Vector.new
    v.type=:nominal
    assert_raise(NoMethodError) { v.check_type(:scale)}
    assert_raise(NoMethodError) { v.check_type(:ordinal)}
    assert(v.check_type(:nominal).nil?)
    
    v.type=:ordinal
    
    assert_raise(NoMethodError) { v.check_type(:scale)}
    
    assert(v.check_type(:ordinal).nil?)
    assert(v.check_type(:nominal).nil?)
    

    v.type=:scale
    assert(v.check_type(:scale).nil?)
    assert(v.check_type(:ordinal).nil?)
    assert(v.check_type(:nominal).nil?)

    v.type=:date
    assert_raise(NoMethodError) { v.check_type(:scale)}
    assert_raise(NoMethodError) { v.check_type(:ordinal)}
    assert_raise(NoMethodError) { v.check_type(:nominal)}
    
  end
  
  
  def test_add
    a=Statsample::Vector.new([1,2,3,4,5], :scale)
    b=Statsample::Vector.new([11,12,13,14,15], :scale)
    assert_equal([3,4,5,6,7], (a+2).to_a)
    assert_equal([12,14,16,18,20], (a+b).to_a)
    assert_raise  ArgumentError do
      a + @c
    end
    assert_raise  TypeError do
      a+"string"
    end
    a=Statsample::Vector.new([nil,1, 2  ,3 ,4 ,5], :scale)
    b=Statsample::Vector.new([11, 12,nil,13,14,15], :scale)
    assert_equal([nil,13,nil,16,18,20], (a+b).to_a)
    assert_equal([nil,13,nil,16,18,20], (a+b.to_a).to_a)
  end
  def test_minus
    a=Statsample::Vector.new([1,2,3,4,5], :scale)
    b=Statsample::Vector.new([11,12,13,14,15], :scale)
    assert_equal([-1,0,1,2,3], (a-2).to_a)
    assert_equal([10,10,10,10,10], (b-a).to_a)
    assert_raise  ArgumentError do
      a-@c
    end
    assert_raise  TypeError do
      a-"string"
    end
    a=Statsample::Vector.new([nil,1, 2  ,3 ,4 ,5], :scale)
    b=Statsample::Vector.new([11, 12,nil,13,14,15], :scale)
    assert_equal([nil,11,nil,10,10,10], (b-a).to_a)
    assert_equal([nil,11,nil,10,10,10], (b-a.to_a).to_a)
  end
  def test_sum_of_squares
    a=[1,2,3,4,5,6].to_vector(:scale)
    assert_equal(17.5, a.sum_of_squared_deviation)
  end
  def test_average_deviation
    a=[1,2,3,4,5,6,7,8,9].to_scale
    assert_equal(20.quo(9), a.average_deviation_population)
  end
  def test_samples
    srand(1)
    assert_equal(100,@c.sample_with_replacement(100).size)
    assert_equal(@c.valid_data.to_a.sort, @c.sample_without_replacement(15).sort)
    assert_raise  ArgumentError do
      @c.sample_without_replacement(20)
    end
    @c.type=:scale
    srand(1)
    assert_equal(100, @c.sample_with_replacement(100).size)
    assert_equal(@c.valid_data.to_a.sort, @c.sample_without_replacement(15).sort)

  end
  def test_valid_data
    a=Statsample::Vector.new([1,2,3,4,"STRING"])
    a.missing_values=[-99]
    a.add(1,false)
    a.add(2,false)
    a.add(-99,false)
    a.set_valid_data
    exp_valid_data=[1,2,3,4,"STRING",1,2]
    assert_equal(exp_valid_data,a.valid_data)
    a.add(20,false)
    a.add(30,false)
    assert_equal(exp_valid_data,a.valid_data)
    a.set_valid_data
    exp_valid_data_2=[1,2,3,4,"STRING",1,2,20,30]
    assert_equal(exp_valid_data_2,a.valid_data)
  end
  def test_set_value
    @c[2]=10
    expected=[5,5,10,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99].to_vector
    assert_equal(expected.data,@c.data)
  end
  def test_gsl
    if Statsample.has_gsl?
      a=Statsample::Vector.new([1,2,3,4,"STRING"], :scale)
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
      assert_equal(21, b.sum)
      assert_equal(3.5, b.mean)
      assert_equal(6,b.gsl.size)
      c=[10,20,30,40,50,100,1000,2000,5000].to_scale
      assert_in_delta(c.skew,     c.skew_slow     ,0.0001)
      assert_in_delta(c.kurtosis, c.kurtosis_slow ,0.0001)
    end
  end
  def test_vector_matrix
    v1=%w{a a a b b b c c}.to_vector
    v2=%w{1 3 4 5 6 4 3 2}.to_vector
    v3=%w{1 0 0 0 1 1 1 0}.to_vector
    ex=Matrix.rows([["a", "1", "1"], ["a", "3", "0"], ["a", "4", "0"], ["b", "5", "0"], ["b", "6", "1"], ["b", "4", "1"], ["c", "3", "1"], ["c", "2", "0"]])
    assert_equal(ex,Statsample.vector_cols_matrix(v1,v2,v3))
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
  def test_paired_ties
    a=[0,0,0,1,1,2,3,3,4,4,4].to_vector(:ordinal)
    expected=[2,2,2,4.5,4.5,6,7.5,7.5,10,10,10].to_vector(:ordinal)
    assert_equal(expected,a.ranked)
  end
  def test_dichotomize
    a=  [0,0,0,1,2,3,nil].to_vector
    exp=[0,0,0,1,1,1,nil].to_scale
    assert_equal(exp,a.dichotomize)
    a=  [1,1,1,2,2,2,3].to_vector
    exp=[0,0,0,1,1,1,1].to_scale
    assert_equal(exp,a.dichotomize)
    a=  [0,0,0,1,2,3,nil].to_vector
    exp=[0,0,0,0,1,1,nil].to_scale
    assert_equal(exp,a.dichotomize(1))
    a= %w{a a a b c d}.to_vector
    exp=[0,0,0,1,1,1].to_scale
    assert_equal(exp, a.dichotomize)
  end
  def test_can_be_methods
    a=  [0,0,0,1,2,3,nil].to_vector
    assert(a.can_be_scale?)
    a=[0,"s",0,1,2,3,nil].to_vector
    assert(!a.can_be_scale?)
    a.missing_values=["s"]
    assert(a.can_be_scale?)

    a=[Date.new(2009,10,10), Date.today(), "2009-10-10", "2009-1-1", nil, "NOW"].to_vector
    assert(a.can_be_date?)
    a=[Date.new(2009,10,10), Date.today(),nil,"sss"].to_vector
    assert(!a.can_be_date?)
  end
  def test_date_vector
    a=[Date.new(2009,10,10), :NOW, "2009-10-10", "2009-1-1", nil, "NOW","MISSING"].to_vector(:date, :missing_values=>["MISSING"])

    assert(a.type==:date)
    expected=[Date.new(2009,10,10), Date.today(), Date.new(2009,10,10), Date.new(2009,1,1), nil, Date.today(), nil ]
    assert_equal(expected, a.date_data_with_nils)
  end
end
