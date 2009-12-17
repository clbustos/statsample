$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'test/unit'
require 'tmpdir'
class TestStatsample
end
class TestStatsample::TestVector < Test::Unit::TestCase

    def setup
		@c = Statsample::Vector.new([5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99], :nominal)
		@c.missing_values=[-99]

    end
    def test_save_load
        outfile=Dir::tmpdir+"/vector.vec"
        @c.save(outfile)
        a=Statsample.load(outfile)
        assert_equal(@c,a)
        
    end
    def test_lazy_methods
        data=[1,2,3,4,5,nil]
        correct=Statsample::Vector.new(data,:scale)
        lazy1=data.to_vector(:scale)
        lazy2=data.to_scale
        assert_equal(correct,lazy1)
        assert_equal(correct,lazy2)
        assert_equal(:scale,lazy2.type)
        assert_equal([1,2,3,4,5],lazy2.valid_data)
    end
    def test_enumerable
        val=@c.collect {|v| v}
        assert_equal(val,[5,5,5,5,5,6,6,7,8,9,10,1,2,3,4,nil,-99,-99])
    end
    def test_recode
        a=@c.recode{|v| @c.is_valid?(v) ? 0 : 1 }
        exp=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1].to_vector
        assert_equal(exp,a)
        exp.recode!{|v| v==0 ? 1:0}
        exp2=(([1]*15)+([0]*3)).to_vector
        assert_equal(exp2,exp)
    end
    def test_product
        a=[1,2,3,4,5].to_vector(:scale)
        assert_equal(120,a.product)
    end
    def test_matrix
        a=[1,2,3,4,5].to_vector(:scale)
        mh=Matrix[[1,2,3,4,5]]
        mv=Matrix.columns([[1,2,3,4,5]])
        assert_equal(mh,a.to_matrix)
        assert_equal(mv,a.to_matrix(:vertical))
        # 3*4 + 2*5 = 22
        a=[3,2].to_vector(:scale)
        b=[4,5].to_vector(:scale)
        assert_equal(22,(a.to_matrix*b.to_matrix(:vertical))[0,0])
    end
	def test_missing_values
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
    def test_has_missing_data
        a=[1,2,3,nil].to_vector
        assert(a.has_missing_data?)
        a=[1,2,3,4,10].to_vector
        assert(!a.has_missing_data?)
        a.missing_values=[10]
        assert(a.has_missing_data?)
    end
    def test_labeled
        @c.labels={5=>'FIVE'}
        assert_equal(["FIVE","FIVE","FIVE","FIVE","FIVE",6,6,7,8,9,10,1,2,3,4,nil,-99, -99],@c.vector_labeled.to_a)
    end
    def test_split
        a = Statsample::Vector.new(["a","a,b","c,d","a,d","d",10,nil],:nominal)
        assert_equal([%w{a},%w{a b},%w{c d},%w{a d},%w{d},[10],nil], a.splitted)
    end
    def test_verify
        h=@c.verify{|d| !d.nil? and d>0}
        e={15=>nil,16=>-99,17=>-99}
        assert_equal(e,h)
    end
    def test_split_by_separator
        a = Statsample::Vector.new(["a","a,b","c,d","a,d",10,nil],:nominal)
        b=a.split_by_separator(",")
        assert_kind_of(Hash, b)
        assert_instance_of(Statsample::Vector,b['a'])
        assert_instance_of(Statsample::Vector,b['b'])
        assert_instance_of(Statsample::Vector,b['c'])
        assert_instance_of(Statsample::Vector,b['d'])
        assert_instance_of(Statsample::Vector,b[10])
        assert_equal([1,1,0,1,0,nil],b['a'].to_a)
        assert_equal([0,1,0,0,0,nil],b['b'].to_a)
        assert_equal([0,0,1,0,0,nil],b['c'].to_a)
        assert_equal([0,0,1,1,0,nil],b['d'].to_a)
        assert_equal([0,0,0,0,1,nil],b[10].to_a)
        assert_equal({'a'=>3,'b'=>1,'c'=>1,'d'=>2,10=>1}, a.split_by_separator_freq())

        a = Statsample::Vector.new(["a","a*b","c*d","a*d",10,nil],:nominal)
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
	def test_ordinal
        @c.type=:ordinal
		assert_equal(5,@c.median)
		assert_equal(4,@c.percentil(25))
		assert_equal(7,@c.percentil(75))
    
    v=[200000, 200000, 210000, 220000, 230000, 250000, 250000, 250000, 270000, 300000, 450000, 130000, 140000, 140000, 140000, 145000, 148000, 165000, 170000, 180000, 180000, 180000, 180000, 180000, 180000 ].to_scale
    assert_equal(180000,v.median)

	end
	def test_ranked
		v1=[0.8,1.2,1.2,2.3,18].to_vector(:ordinal)
		expected=[1,2.5,2.5,4,5].to_vector(:ordinal)
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
    def test_vector_standarized
        v1=[1,2,3,4,nil].to_vector(:scale)
        sds=v1.sds
        expected=[((1-2.5).quo(sds)),((2-2.5).quo(sds)),((3-2.5).quo(sds)),((4-2.5).quo(sds)), nil].to_vector(:scale)
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
		if HAS_GSL
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
