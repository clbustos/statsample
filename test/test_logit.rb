require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))
$:.unshift("/home/cdx/dev/rserve-client/lib")
class StatsampleLogitTestCase < MiniTest::Unit::TestCase
  context Statsample::Regression::Binomial::Logit do
    should "return correct values for example" do
      crime=File.dirname(__FILE__)+'/fixtures/test_binomial.csv'
      ds=Statsample::CSV.read(crime)
      lr=Statsample::Regression::Binomial::Logit.new(ds,'y')
      assert_in_delta(-38.8669,lr.log_likehood,0.001)
      assert_in_delta(-5.3658,lr.constant,0.001)
  
      exp_coeffs={"a"=>0.3270,"b"=>0.8147, "c"=>-0.4031}
      exp_coeffs.each{|k,v|
        assert_in_delta(v,lr.coeffs[k],0.001)
      }
      exp_errors={'a'=>0.4390,'b'=>0.4270,'c'=>0.3819}
      exp_errors.each{|k,v|
        assert_in_delta(v,lr.coeffs_se[k],0.001)
      }
      assert_equal(7,lr.iterations)
      end
    end
    begin
      require 'rserve'
      require 'statsample/rserve_extension'
      should "return same similat values to as R gml" do
       
        r=Rserve::Connection.new
        ran=Distribution::Normal.rng_ugaussian
        samples=100
        a,b,c=ran.call,ran.call,ran.call
        logit=lambda {|x| Math.exp(x) / (1+Math.exp(x))}
        
        x1=Statsample::Vector.new_scale(samples) {ran.call}
        x2=Statsample::Vector.new_scale(samples) {ran.call}
        x3=Statsample::Vector.new_scale(samples) {ran.call}

        y= Statsample::Vector.new_scale(samples) {|i| logit.call(x1[i]*a+x2[i]*b+x3[i]*c+ran.call)}
        # Generate R object
        ds={'x1'=>x1,'x2'=>x2,'x3'=>x3,'y'=>y}.to_dataset
        r.assign('ds',ds)
        r.eval("mylogit<- glm(ds$y~ds$x1+ds$x2+ds$x3, family=binomial(link='logit'), na.action=na.pass)")
        
        r_logit=r.eval('summary(mylogit)')        
        r_coeffs=r_logit.as_list['coefficients'].to_ruby
        ruby_logit=Statsample::Regression::Binomial::Logit.new(ds,'y')

        assert_in_delta(r_coeffs[0,0],  ruby_logit.constant,1e-10)
        assert_in_delta(r_coeffs[0,1],  ruby_logit.constant_se,1e-7)
        
        %w{x1 x2 x3}.each_with_index do |f,i|
          assert_in_delta(r_coeffs[i+1,0], ruby_logit.coeffs[f],1e-10)
          assert_in_delta(r_coeffs[i+1,1], ruby_logit.coeffs_se[f],1e-7)
          
        end
        
        r.close
        
      end
      
    rescue LoadError
      puts "Require rserve extension"
    
  end  
end
