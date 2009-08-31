$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'test/unit'
class StatsampleMLETestCase < Test::Unit::TestCase
    def atest_normal
        cases=200
        a=Array.new()
        b=Array.new()
        c=Array.new()
        y=Array.new()

        cases.times{|i|
            a_val=2*rand()-1
            b_val=6*rand()-3
            c_val=8*rand()-4
            a.push(a_val)
            b.push(b_val)
            c.push(c_val)
            y_val=a_val+b_val+c_val+rand()*3
            y.push(y_val)
        }
        a=a.to_vector(:scale)
        b=b.to_vector(:scale)
        c=c.to_vector(:scale)
        y=y.to_vector(:scale)
        ds_indep={'a'=>a,'b'=>b,'c'=>c}.to_dataset
        constant=([1]*ds_indep.cases).to_vector(:scale)
        ds_indep_2={'constant'=>constant,'a'=>a,'b'=>b,'c'=>c}.to_dataset
        ds_indep_2.fields=%w{constant a b c}
        mat_x=ds_indep_2.to_matrix
        mat_y=y.to_matrix(:vertical)
        coeffs_nr=Statsample::MLE.newton_raphson(mat_x,mat_y, Statsample::MLE::Normal)
        ds=ds_indep.dup
        ds.add_vector('y',y)
        lr=Statsample::Regression::Multiple.listwise(ds,'y')
        lr_constant = lr.constant
        lr_coeffs   = lr.coeffs
        p coeffs_nr
        p lr_coeffs
        assert_in_delta(coeffs_nr[0,0], lr_constant,0.0000001)
        assert_in_delta(coeffs_nr[1,0], lr_coeffs["a"],0.0000001)
        assert_in_delta(coeffs_nr[2,0], lr_coeffs["b"],0.0000001)
        assert_in_delta(coeffs_nr[3,0], lr_coeffs["c"],0.0000001)
    end
    def atest_logit1
        
        cases=200
        a=Array.new()
        b=Array.new()
        c=Array.new()
        y=Array.new()

        cases.times{|i|
            a.push(2*rand()-i)
            b.push(2*rand()-5+i)
            c.push(2*rand()+i)
            y_val=i+(rand()*cases.quo(2) - cases.quo(4))
            y.push(y_val<(cases/2.0) ? 0.0 : 1.0)
        }
        a=a.to_vector(:scale)
        b=b.to_vector(:scale)
        c=c.to_vector(:scale)
        y=y.to_vector(:scale)
        
        ds_indep={'a'=>a,'b'=>b,'c'=>c}.to_dataset
        constant=([1.0]*cases).to_vector(:scale)
        ds_indep_2={'constant'=>constant,'a'=>a,'b'=>b,'c'=>c}.to_dataset
        ds_indep_2.fields=%w{constant a b c}
        mat_x=ds_indep_2.to_matrix
        mat_y=y.to_matrix(:vertical)
        ds=ds_indep.dup
        ds.add_vector('y',y)
        #ds.each_array{|row|
        #    puts row.join(",")
        #}
=begin
        ds=Statsample::CSV.read("test_binomial.csv")
        constant=([1.0]*ds.cases).to_vector(:scale)
        
        ds_indep={'constant'=>constant, 'a'=>ds['a'],'b'=>ds['b'], 'c'=>ds['c']}.to_dataset(%w{constant a b c})
        
        mat_x=ds_indep.to_matrix
        mat_y=ds['y'].to_matrix(:vertical)
=end
        log=Alglib::Logit.build_from_matrix(ds.to_matrix)
        coeffs=log.unpack[0]
        b=Matrix.columns([[-coeffs[3],-coeffs[0],-coeffs[1],-coeffs[2]]])
#        puts "Coeficientes beta alglib:"
#        p b
        mle_alglib=Statsample::MLE::ln_mle(Statsample::MLE::Logit, mat_x,mat_y,b)
#       puts "MLE Alglib:"
#        p mle_alglib
#        Statsample::CSV.write(ds,"test_binomial.csv")



#        puts "iniciando newton"
        coeffs_nr=Statsample::MLE.newton_raphson(mat_x,mat_y, Statsample::MLE::Logit)
#        p coeffs_nr
        mle_pure_ruby=Statsample::MLE::ln_mle(Statsample::MLE::Logit, mat_x,mat_y,coeffs_nr)
#        p mle_pure_ruby

        #puts "Malo: #{mle_malo} Bueno: #{mle_bueno} : #{mle_malo-mle_bueno}"
    end
end

