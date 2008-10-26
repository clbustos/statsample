require File.dirname(__FILE__)+'/../lib/rubyss'
require 'rubyss/multiset'
require 'test/unit'

class RubySSGGobiTestCase < Test::Unit::TestCase

	def initialize(*args)
		super
		v1=([10.2,20.3,10,20,30,40,30,20,30,40]*10).to_vector(:scale)
		@v2=(%w{a b c a a a b b c d}*10).to_vector(:nominal)
		@v2.labels={"a"=>"letter a","d"=>"letter d"}
		v3=([1,2,3,4,5,4,3,2,1,2]*10).to_vector(:ordinal)
		@ds={'v1'=>v1,'v2'=>@v2,'v3'=>v3}.to_dataset
	end
	def test_values_definition
		a=[1.0,2,"a"]
		assert_equal("<real>1.0</real> <int>2</int> <string>a</string>",RubySS::GGobi.values_definition(a))
	end
	def test_variable_definition
		carrier=OpenStruct.new
		carrier.categorials=[]
		carrier.conversions={}
		real_var_definition=RubySS::GGobi.variable_definition(carrier,@v2,'variable 2',"v2")
		expected=<<EOS
<categoricalvariable name="variable 2" nickname="v2">
<levels count="4">
<level value="1">letter a</level>
<level value="2">b</level>
<level value="3">c</level>
<level value="4">letter d</level></levels>
</categoricalvariable>
EOS
assert_equal(expected.gsub(/\s/," "),real_var_definition.gsub(/\s/," "))
assert_equal({'variable 2'=>{'a'=>1,'b'=>2,'c'=>3,'d'=>4}},carrier.conversions)
	assert_equal(['variable 2'],carrier.categorials)
	end
	def test_out
		filename="/tmp/test_rubyss_ggobi.xml"
		go=RubySS::GGobi.out(@ds)
		
	end
end
