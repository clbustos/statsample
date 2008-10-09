require File.dirname(__FILE__)+'/../lib/rubyss'
require 'test/unit'

class RubySSResampleTestCase < Test::Unit::TestCase
	def initialize(*args)
		super
	end
    def test_basic
        r=RubySS::Resample.generate(20,1,10)
        assert_equal(20,r.size)
        assert(r.min>=1)
        assert(r.max<=10)
    end
    def test_repeat_and_save
        r=RubySS::Resample.repeat_and_save(400) {
            RubySS::Resample.generate(20,1,10).count(1.0)
        }
        assert_equal(400,r.size)
        v=RubySS::Vector.new(r,:scale)
        a=v.count {|x|  x > 3}
        assert(a>=30 && a<=70)
    end
end