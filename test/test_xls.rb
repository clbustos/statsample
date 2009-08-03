require File.dirname(__FILE__)+'/../lib/statsample'
require 'test/unit'
require 'tmpdir'
begin
	require 'spreadsheet'
rescue LoadError
	puts "You should install spreadsheet (gem install spreadsheet)"
end
class StatsampleExcelTestCase < Test::Unit::TestCase
	def initialize(*args)
        @ds=Statsample::Excel.read(File.dirname(__FILE__)+"/test_xls.xls")
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
        Statsample::Excel.write(@ds,filename)
        ds2=Statsample::Excel.read(filename)
        i=0
        ds2.each_array{|row|
            assert_equal(@ds.case_as_array(i),row)
               i+=1
        }
    end
end