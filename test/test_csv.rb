$:.unshift(File.dirname(__FILE__)+'/../lib/')
require 'statsample'
require 'tmpdir'
require 'test/unit'

class StatsampleCSVTestCase < Test::Unit::TestCase
    def setup
        @ds=Statsample::CSV.read(File.dirname(__FILE__)+"/test_csv.csv")
    end
    def test_read
        assert_equal(6,@ds.cases)
        assert_equal(%w{id name age city a1},@ds.fields)
        id=[1,2,3,4,5,6].to_vector(:scale)
        name=["Alex","Claude","Peter","Franz","George","Fernand"].to_vector(:nominal)
        age=[20,23,25,27,5.5,nil].to_vector(:scale)
        city=["New York","London","London","Paris","Tome",nil].to_vector(:nominal)
        a1=["a,b","b,c","a",nil,"a,b,c",nil].to_vector(:nominal)
        ds_exp=Statsample::Dataset.new({'id'=>id,'name'=>name,'age'=>age,'city'=>city,'a1'=>a1}, %w{id name age city a1})
        ds_exp.fields.each{|f|
            assert_equal(ds_exp[f],@ds[f])
        }
        assert_equal(ds_exp,@ds)
        

    end
    def test_nil
        assert_equal(nil,@ds['age'][5])
    end
    def test_repeated
      ds=Statsample::CSV.read(File.dirname(__FILE__)+"/../data/repeated_fields.csv")
      assert_equal(%w{id name_1 age_1 city a1 name_2 age_2},ds.fields)
      age=[3,4,5,6,nil,8].to_vector(:scale)
      assert_equal(age,ds['age_2'])
    end
    def test_write
        filename=Dir::tmpdir+"/test_write.csv"
        Statsample::CSV.write(@ds,filename)
        ds2=Statsample::CSV.read(filename)
        i=0
        ds2.each_array{|row|
            assert_equal(@ds.case_as_array(i),row)
               i+=1
        }
    end
end