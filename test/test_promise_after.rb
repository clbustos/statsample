require(File.dirname(__FILE__)+'/test_helpers.rb')


class StatsamplePromiseAfterTestCase < MiniTest::Unit::TestCase
  class ExpensiveClass
    extend Statsample::PromiseAfter
    attr_reader :a, :dirty
    def initialize
      @a=nil
      @b=nil
      @dirty=false
    end
    def compute
      @a="After"
      @b="After"
      @dirty=true
    end
    def a
      @a.nil? ? nil : "@a=#{@a}"
    end
    def b
      "@b=#{@b}"
    end
    promise_after :compute, :a
  end
  def setup
    @ec=ExpensiveClass.new
  end
  def test_promise_after_before
    assert_equal(nil, @ec.instance_variable_get("@a")) 
    assert_equal(nil, @ec.instance_variable_get("@b")) 
    assert_equal("@b=",@ec.b)
    refute(@ec.dirty) 
    # Calling method a active compute
    assert_equal("@a=After", @ec.a) 
    assert(@ec.dirty)
    assert_equal("@b=After", @ec.b) 
  end
end
