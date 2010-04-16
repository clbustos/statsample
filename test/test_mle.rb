require(File.dirname(__FILE__)+'/helpers_tests.rb')

class StatsampleMLETestCase < MiniTest::Unit::TestCase
  def setup
    @file_binomial=File.dirname(__FILE__)+'/../data/test_binomial.csv'
    @crime=File.dirname(__FILE__)+'/../data/crime.txt'
    @cases=100
    a=Array.new()
    b=Array.new()
    c=Array.new()
    y=Array.new()

    @cases.times{|i|
      a.push(2*rand()-i)
      b.push(2*rand()-5+i)
      c.push(2*rand()+i)
      y_val=i+(rand()*@cases.quo(2) - @cases.quo(4))
      y.push(y_val<(@cases/2.0) ? 0.0 : 1.0)
    }
    a=a.to_vector(:scale)
    b=b.to_vector(:scale)
    c=c.to_vector(:scale)
    y=y.to_vector(:scale)

    @ds_indep={'a'=>a,'b'=>b,'c'=>c}.to_dataset
    constant=([1.0]*@cases).to_vector(:scale)
    @ds_indep_2={'constant'=>constant,'a'=>a,'b'=>b,'c'=>c}.to_dataset
    @ds_indep_2.fields=%w{constant a b c}
    @mat_x=@ds_indep_2.to_matrix
    @mat_y=y.to_matrix(:vertical)
    @ds=@ds_indep.dup
    @ds.add_vector('y',y)
  end
  def test_normal
    y=Array.new()
    y=@ds_indep.collect{|row|
      row['a']*5+row['b']+row['c']+rand()*3
    }
    constant=([1]*@cases).to_vector(:scale)
    ds_indep_2=@ds_indep.dup
    ds_indep_2['constant']=constant
    ds_indep_2.fields=%w{constant a b c}
    mat_x=ds_indep_2.to_matrix
    mat_y=y.to_matrix(:vertical)
    mle=Statsample::MLE::Normal.new()
    mle.verbose=false
    coeffs_nr=mle.newton_raphson(mat_x,mat_y)
    #p coeffs_nr
    ds=@ds_indep.dup
    ds.add_vector('y',y)
    lr=Statsample::Regression.multiple(ds, 'y')
    lr_constant = lr.constant
    lr_coeffs   = lr.coeffs
    assert_in_delta(coeffs_nr[0,0], lr_constant,0.0000001)
    assert_in_delta(coeffs_nr[1,0], lr_coeffs["a"],0.0000001)
    assert_in_delta(coeffs_nr[2,0], lr_coeffs["b"],0.0000001)
    assert_in_delta(coeffs_nr[3,0], lr_coeffs["c"],0.0000001)
  end

  def test_probit
    ds=Statsample::CSV.read(@file_binomial)
    constant=([1.0]*ds.cases).to_vector(:scale)
    ds_indep={'constant'=>constant, 'a'=>ds['a'],'b'=>ds['b'], 'c'=>ds['c']}.to_dataset(%w{constant a b c})
    mat_x=ds_indep.to_matrix
    mat_y=ds['y'].to_matrix(:vertical)
    mle=Statsample::MLE::Probit.new
    b_probit=mle.newton_raphson(mat_x,mat_y)
    ll=mle.log_likehood(mat_x,mat_y,b_probit)

    b_exp=[-3.0670,0.1763,0.4483,-0.2240]
    b_exp.each_index{|i|
      assert_in_delta(b_exp[i], b_probit[i,0], 0.001)
    }
    assert_in_delta(-38.31559,ll,0.0001)
  end
  def test_logit_crime
    ds=Statsample::PlainText.read(@crime, %w{crimerat maleteen south educ police60 police59 labor  males pop nonwhite unemp1  unemp2 median belowmed})
    constant=([1.0]*ds.cases).to_vector(:scale)
    ds2=ds.dup(%w{maleteen south educ police59})
    ds2['constant']=constant
    ds2.fields=%w{constant maleteen south educ police59}
    mat_x=ds2.to_matrix
    mat_y=(ds.compute "(crimerat>=110) ? 1:0").to_matrix(:vertical)
    mle=Statsample::MLE::Logit.new
    b=mle.newton_raphson(mat_x,mat_y)
    ll=mle.log_likehood(mat_x,mat_y,b)
    assert_in_delta(-18.606959,ll,0.001)
    exp=[-17.701, 0.0833,-1.117, 0.0229, 0.0581]
    exp.each_index{|i|
      assert_in_delta(exp[i],b[i,0],0.001)
    }
    assert_equal(5,mle.iterations)
  end
  def atest_logit_alglib
    if(HAS_ALGIB)
      ds=Statsample::CSV.read(@file_binomial)
      constant=([1.0]*ds.cases).to_vector(:scale)

      ds_indep={'constant'=>constant, 'a'=>ds['a'],'b'=>ds['b'], 'c'=>ds['c']}.to_dataset(%w{constant a b c} )

      mat_x=ds_indep.to_matrix
      mat_y=ds['y'].to_matrix(:vertical)
      log=Alglib::Logit.build_from_matrix(ds.to_matrix)
      coeffs=log.unpack[0]
      b_alglib=Matrix.columns([[-coeffs[3], -coeffs[0], -coeffs[1], -coeffs[2]]])
      mle=Statsample::MLE::Logit.new
      ll_alglib=mle.log_likehood(mat_x,mat_y,b_alglib)
      b_newton=mle.newton_raphson(mat_x,mat_y)
      ll_pure_ruby=mle.log_likehood(mat_x,mat_y,b_newton)
      #p b_alglib
      #p b_newton

      assert_in_delta(ll_alglib,ll_pure_ruby,1)
    end

  end
  def atest_logit1
    log=Alglib::Logit.build_from_matrix(@ds.to_matrix)
    coeffs=log.unpack[0]
    b=Matrix.columns([[-coeffs[3],-coeffs[0],-coeffs[1],-coeffs[2]]])
    #        puts "Coeficientes beta alglib:"
    #p b
    mle_alglib=Statsample::MLE::ln_mle(Statsample::MLE::Logit, @mat_x,@mat_y,b)
    #       puts "MLE Alglib:"
    #p mle_alglib
    #        Statsample::CSV.write(ds,"test_binomial.csv")



    #        puts "iniciando newton"
    coeffs_nr=Statsample::MLE.newton_raphson(@mat_x,@mat_y, Statsample::MLE::Logit)
    #p coeffs_nr
    mle_pure_ruby=Statsample::MLE::ln_mle(Statsample::MLE::Logit, @mat_x,@mat_y,coeffs_nr)
    #p mle_pure_ruby

    #puts "Malo: #{mle_malo} Bueno: #{mle_bueno} : #{mle_malo-mle_bueno}"
  end
end

