$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'test/unit'
class StatsampleLogitTestCase < Test::Unit::TestCase
    def test_logit
        crime=File.dirname(__FILE__)+'/../data/crime.txt'
        ds=Statsample::PlainText.read(crime, %w{crimerat maleteen south educ police60 police59 labor  males pop nonwhite unemp1  unemp2 median belowmed})
        ds2=ds.dup(%w{maleteen south educ police59})
        y=(ds.compute "(crimerat>=110) ? 1:0")
        ds2.add_vector('y',y)
        lr=Statsample::Regression::Binomial::Logit.new(ds2,'y')
        assert_in_delta(-18.606959,lr.log_likehood,0.001)
        assert_in_delta(-17.701,lr.constant,0.001)
        
        exp={"maleteen"=>0.0833,"south"=>-1.117,"educ"=> 0.0229, "police59"=>0.0581}
        exp.each{|k,v|
            assert_in_delta(v,lr.coeffs[k],0.001)
        }
        assert_equal(5,lr.iterations)               
    end
end
