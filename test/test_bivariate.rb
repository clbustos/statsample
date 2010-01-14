$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'test/unit'
class StatsampleBivariateTestCase < Test::Unit::TestCase
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
  def test_tetrachoric_matrix
    ds=Statsample::PlainText.read(File.dirname(__FILE__)+"/../data/tetmat_test.txt", %w{a b c d e})
    tcm_obs=Statsample::Bivariate.tetrachoric_correlation_matrix(ds)
    tcm_exp=Statsample::PlainText.read(File.dirname(__FILE__)+"/../data/tetmat_matrix.txt", %w{a b c d e}).to_matrix
    tcm_obs.row_size.times do |i|
      tcm_obs.column_size do |j|
        assert_in_delta(tcm_obs[i,j], tcm_exp[i,k], 0.00001)
      end
    end
  end
  def test_tetrachoric
    a,b,c,d=0,0,0,0
    assert_raise RuntimeError do
      tc  = Statsample::Bivariate::Tetrachoric.new(a,b,c,d)
    end
    a,b,c,d=10,10,0,0
    assert_raise RuntimeError do
      tc  = Statsample::Bivariate::Tetrachoric.new(a,b,c,d)
    end
    a,b,c,d=10,0,10,0
    assert_raise RuntimeError do
      tc  = Statsample::Bivariate::Tetrachoric.new(a,b,c,d)
    end
    a,b,c,d=10,0,0,10
    tc  = Statsample::Bivariate::Tetrachoric.new(a,b,c,d)
    assert_equal(1,tc.r)
    assert_equal(0,tc.se)
    a,b,c,d=0,10,10,0
    tc  = Statsample::Bivariate::Tetrachoric.new(a,b,c,d)
    assert_equal(-1,tc.r)
    assert_equal(0,tc.se)
    
    a,b,c,d = 30,40,70,20
    tc  = Statsample::Bivariate::Tetrachoric.new(a,b,c,d)
    assert_in_delta(-0.53980,tc.r,0.0001)
    assert_in_delta(0.09940,tc.se,0.0001)
    assert_in_delta(0.31864,tc.threshold_x,0.0001)
    assert_in_delta(-0.15731,tc.threshold_y,0.0001)
    x=%w{a a a a b b b a b b a a b b}.to_vector
    y=%w{0 0 1 1 0 0 1 1 1 1 0 0 1 1}.to_vector
    # crosstab
    #    0    1
    # a  4    3
    # b  2    5
    a,b,c,d=4,3,2,5
    tc1  = Statsample::Bivariate::Tetrachoric.new(a,b,c,d)
    tc2  = Statsample::Bivariate::Tetrachoric.new_with_vectors(x,y)
    assert_equal(tc1.r,tc2.r)
    assert_equal(tc1.se,tc2.se)
    
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
end
