$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'test/unit'
class StatsampleLogitTestCase < Test::Unit::TestCase
    def test_basic
        a=  [1,3,2,4,3,5,4,6,5,7].to_vector(:scale)
        b=  [30,32,44,45,56,57,68,69,49,49].to_vector(:scale)
        c=  [3,5,2,7,9,4,2,5,6,8].to_vector(:scale)
        y=  [0,0,0,0,0,1,1,1,1,1].to_vector(:scale)
        e=1.upto(10).to_a.collect{|i| rand()}.to_vector(:scale)
        ds={'a'=>a,'b'=>b,'c'=>c,'e'=>e,'y'=>y}.to_dataset
        l=Statsample::Regression::Logit.new(ds,"y")
        b=[3,-0.5,4,2]
        assert_in_delta(Math::log(l.mle(b)), l.mle_log(b),0.0000001)
        p l.test_first_derivative(b.to_vector(:scale))
        p l.first_derivative(b.to_vector(:scale))

    end
    def atest_logit
        a=  [1,3,2,4,3,5,4,6,5,7].to_vector(:scale)
        b=  [3,3,4,4,5,5,6,6,4,4].to_vector(:scale)
        c=  [11,22,30,40,50,65,78,79,99,100].to_vector(:scale)
        e=1.upto(10).to_a.collect{|i| 2}
        em= Matrix.columns([e])
        k=3
        n=10
        sigma2 = 0.1
        ds_indep={'a'=>a,'b'=>b,'c'=>c}.to_dataset
        x=ds_indep.to_matrix
        beta=Matrix[[5],[-7],[10]]
        y = x*(beta)+(em)
        #parameters to estimate
        pa = Array.new(k+1)
        k.times{|i| pa[i] = [rand()]}
        pa[k] = [sigma2]
        paras = Matrix.rows(pa , true)
        p paras
        require 'statsample/regression/normal'
        new_paras = Statsample::Regression::Logit.newton_raphson(x,y,paras, Normal.new)
        p new_paras
    end
end
