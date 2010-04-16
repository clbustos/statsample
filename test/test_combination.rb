require(File.dirname(__FILE__)+'/helpers_tests.rb')

class StatsampleCombinationTestCase < MiniTest::Unit::TestCase
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
    if Statsample.has_gsl?
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
      skip "Not CombinationRuby vs CombinationGSL (no gsl)"
    end
  end
end
