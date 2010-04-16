require(File.dirname(__FILE__)+'/helpers_tests.rb')


class StatsampleStratifiedTestCase < MiniTest::Unit::TestCase

  def initialize(*args)
    super
  end
  def test_mean
    a=[10,20,30,40,50]
    b=[110,120,130,140]
    pop=a+b
    av=a.to_vector(:scale)
    bv=b.to_vector(:scale)
    popv=pop.to_vector(:scale)
    assert_equal(popv.mean,Statsample::StratifiedSample.mean(av,bv))
  end
end
