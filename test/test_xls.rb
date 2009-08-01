require File.dirname(__FILE__)+'/../lib/rubyss'
require 'test/unit'
require 'tmpdir'
begin
	require 'spreadsheet'
rescue LoadError
	puts "You should install spreadsheet (gem install spreadsheet)"
end
class RubySSExcelTestCase < Test::Unit::TestCase
	def initialize(*args)
        @ds=RubySS::Excel.read(File.dirname(__FILE__)+"/test_xls.xls")
		super
	end
    
    def test_read
        assert_equal(6,@ds.cases)
        assert_equal(%w{id name age city a1},@ds.fields)
    end
    def test_nil
        assert_equal(nil,@ds['age'][5])
    end
    def test_write
        filename=Dir::tmpdir+"/test_write.xls"
        RubySS::Excel.write(@ds,filename)
        ds2=RubySS::Excel.read(filename)
        i=0
        ds2.each_array{|row|
            assert_equal(@ds.case_as_array(i),row)
               i+=1
        }
    end
end