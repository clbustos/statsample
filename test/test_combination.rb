$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'test/unit'

class StatsampleCombinationTestCase < Test::Unit::TestCase
	def initialize(*args)
        super
	end
    def test_basic
        k=3
        n=5
        expected=[[0,1,2],[0,1,3],[0,1,4],[0,2,3],[0,2,4],[0,3,4],[1,2,3],[1,2,4],[1,3,4],[2,3,4]]
        comb=Statsample::Combination.new(k,n)
        a=[]
        comb.each{|y|
            a.push(y)
        }
        assert_equal(expected,a)
    end
    def test_gsl_versus_ruby
        if HAS_GSL
        k=3
        n=10
        gsl=Statsample::Combination.new(k,n,false)
        gsl_array=[]
        gsl.each{|y|
            gsl_array.push(y)
        }
        rb=Statsample::Combination.new(k,n,true)
        rb_array=[]
        rb.each{|y|
            rb_array.push(y)
        }
        assert(gsl.d.is_a?(Statsample::Combination::CombinationGsl))
        assert(rb.d.is_a?(Statsample::Combination::CombinationRuby))
        
        assert_equal(rb_array,gsl_array)
    else
            puts "Not CombinationRuby vs CombinationGSL (no gsl)"
        end
    end
end