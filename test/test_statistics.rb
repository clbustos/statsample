$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'test/unit'
class StatsampleStatisicsTestCase < Test::Unit::TestCase

	def initialize(*args)
		super
	end
    def test_is_number
        assert("10".is_number?)
        assert("-10".is_number?)
        assert("0.1".is_number?)
        assert("-0.1".is_number?)
        assert("10e3".is_number?)
        assert("10e-3".is_number?)
        assert(!"1212-1212-1".is_number?)
        assert(!"a10".is_number?)
        assert(!"".is_number?)

    end
    def test_chi_square
        assert_raise TypeError do
            Statsample::Test.chi_square(1,1)
        end
        real=Matrix[[95,95],[45,155]]
        expected=Matrix[[68,122],[72,128]]
        assert_nothing_raised do
            chi=Statsample::Test.chi_square(real,expected)
        end
        chi=Statsample::Test.chi_square(real,expected)
        assert_in_delta(32.53,chi,0.1)
    end
	def test_sum_of_codeviated
		v1=[1,2,3,4,5,6].to_vector(:scale)
		v2=[6,2,4,10,12,8].to_vector(:scale)
		assert_equal(23.0, Statsample::Bivariate.sum_of_codeviated(v1,v2))
	end
    def test_pearson
        v1=[6,5,4,7,8,4,3,2].to_vector(:scale)
        v2=[2,3,7,8,6,4,3,2].to_vector(:scale)
        assert_in_delta(0.525,Statsample::Bivariate.pearson(v1,v2), 0.001)
        v3=[6,2,  1000,1000,5,4,7,8,4,3,2,nil].to_vector(:scale)
        v4=[2,nil,nil,nil,  3,7,8,6,4,3,2,500].to_vector(:scale)
        assert_in_delta(0.525,Statsample::Bivariate.pearson(v3,v4),0.001)
    end
    def test_matrix_correlation
        v1=[6,5,4,7,8,4,3,2].to_vector(:scale)
        v2=[2,3,7,8,6,4,3,2].to_vector(:scale)
        v3=[6,2,  1000,1000,5,4,7,8].to_vector(:scale)
        v4=[2,nil,nil,nil,  3,7,8,6].to_vector(:scale)
        ds={'v1'=>v1,'v2'=>v2,'v3'=>v3,'v4'=>v4}.to_dataset
        c=Proc.new {|n1,n2|Statsample::Bivariate.pearson(n1,n2)} 
        expected=Matrix[ [c.call(v1,v1),c.call(v1,v2),c.call(v1,v3),c.call(v1,v4)], [c.call(v2,v1),c.call(v2,v2),c.call(v2,v3),c.call(v2,v4)], [c.call(v3,v1),c.call(v3,v2),c.call(v3,v3),c.call(v3,v4)],
        [c.call(v4,v1),c.call(v4,v2),c.call(v4,v3),c.call(v4,v4)]
        ]
	obt=Statsample::Bivariate.correlation_matrix(ds)
	for i in 0...expected.row_size
	for j in 0...expected.column_size
		#puts expected[i,j].inspect
		#puts obt[i,j].inspect
		assert_in_delta(expected[i,j], obt[i,j],0.0001,"#{expected[i,j].class}!=#{obt[i,j].class}  ")
	end
	end
#assert_equal(expected,obt)
    end
    def test_prop_pearson
        assert_in_delta(0.42, Statsample::Bivariate.prop_pearson(Statsample::Bivariate.t_r(0.084,94), 94),0.01)
        assert_in_delta(0.65, Statsample::Bivariate.prop_pearson(Statsample::Bivariate.t_r(0.046,95), 95),0.01)
        r=0.9
        n=100
        t=Statsample::Bivariate.t_r(r,n)
        assert(Statsample::Bivariate.prop_pearson(t,n,:both)<0.05)
        assert(Statsample::Bivariate.prop_pearson(t,n,:right)<0.05)
        assert(Statsample::Bivariate.prop_pearson(t,n,:left)>0.05)

        r=-0.9
        n=100
        t=Statsample::Bivariate.t_r(r,n)
        assert(Statsample::Bivariate.prop_pearson(t,n,:both)<0.05)
        assert(Statsample::Bivariate.prop_pearson(t,n,:right)>0.05)
        assert(Statsample::Bivariate.prop_pearson(t,n,:left)<0.05)
    end
	def test_covariance
		if HAS_GSL
			v1=[6,5,4,7,8,4,3,2].to_vector(:scale)
			v2=[2,3,7,8,6,4,3,2].to_vector(:scale)
			assert_in_delta(Statsample::Bivariate.covariance(v1,v2), Statsample::Bivariate.covariance_slow(v1,v2), 0.001)
			
		end
	end

	def test_spearman
		v1=[86,97,99,100,101,103,106,110,112,113].to_vector(:scale)
		v2=[0,20,28,27,50,29,7,17,6,12].to_vector(:scale)
        assert_in_delta(-0.175758,Statsample::Bivariate.spearman(v1,v2),0.0001)
        
	end
	def test_point_biserial
		c=[1,3,5,6,7,100,200,300,400,300].to_vector(:scale)
		d=[1,1,1,1,1,0,0,0,0,0].to_vector(:scale)
		assert_raise TypeError do
			Statsample::Bivariate.point_biserial(c,d)
		end
		assert_in_delta(Statsample::Bivariate.point_biserial(d,c), Statsample::Bivariate.pearson(d,c), 0.0001)
	end
	def test_tau
		v1=[1,2,3,4,5,6,7,8,9,10,11].to_vector(:ordinal)
		v2=[1,3,4,5,7,8,2,9,10,6,11].to_vector(:ordinal)
		assert_in_delta(0.6727,Statsample::Bivariate.tau_a(v1,v2),0.001)
		assert_in_delta(0.6727,Statsample::Bivariate.tau_b((Statsample::Crosstab.new(v1,v2).to_matrix)),0.001)
		v1=[12,14,14,17,19,19,19,19,19,20,21,21,21,21,21,22,23,24,24,24,26,26,27].to_vector(:ordinal)
		v2=[11,4,4,2,0,0,0,0,0,0,4,0,4,0,0,0,0,4,0,0,0,0,0].to_vector(:ordinal)
		assert_in_delta(-0.376201540231705, Statsample::Bivariate.tau_b(Statsample::Crosstab.new(v1,v2).to_matrix),0.001)
	end
	def test_gamma
		m=Matrix[[10,5,2],[10,15,20]]
		assert_in_delta(0.636,Statsample::Bivariate.gamma(m),0.001)
		m2=Matrix[[15,12,6,5],[12,8,10,8],[4,6,9,10]]
		assert_in_delta(0.349,Statsample::Bivariate.gamma(m2),0.001)
		

	end
    def test_estimation_mean              
        v=([42]*23+[41]*4+[36]*1+[32]*1+[29]*1+[27]*2+[23]*1+[19]*1+[16]*2+[15]*2+[14,11,10,9,7]+ [6]*3+[5]*2+[4,3]).to_vector(:scale)
        assert_equal(50,v.size)
        assert_equal(1471,v.sum())
        limits=Statsample::SRS.mean_confidence_interval_z(v.mean(), v.sds(), v.size,676,0.80)
    end
    def test_estimation_proportion
        # total
        pop=3042
        sam=200
        prop=0.19
        assert_in_delta(81.8, Statsample::SRS.proportion_total_sd_ep_wor(prop, sam, pop), 0.1)
        
        # confidence limits
        pop=500
        sam=100
        prop=0.37
        a=0.95
        l= Statsample::SRS.proportion_confidence_interval_z(prop, sam, pop, a)
        assert_in_delta(0.28,l[0],0.01)
        assert_in_delta(0.46,l[1],0.01)
    end
    def test_ml
        if(true)
		real=[1,1,1,1].to_vector(:scale)
		
		pred=[0.0001,0.0001,0.0001,0.0001].to_vector(:scale)
        # puts  Statsample::Bivariate.maximum_likehood_dichotomic(pred,real)

        end
    end
    def test_simple_linear_regression
		a=[1,2,3,4,5,6].to_vector(:scale)
		b=[6,2,4,10,12,8].to_vector(:scale)
		reg = Statsample::Regression::Simple.new_from_vectors(a,b)
        assert_in_delta((reg.ssr+reg.sse).to_f,reg.sst,0.001)
        assert_in_delta(Statsample::Bivariate.pearson(a,b),reg.r,0.001)
		assert_in_delta(2.4,reg.a,0.01)
		assert_in_delta(1.314,reg.b,0.001)
		assert_in_delta(0.657,reg.r,0.001)
		assert_in_delta(0.432,reg.r2,0.001)
        
	end    
end
