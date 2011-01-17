require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))
class StatsampleExcelTestCase < MiniTest::Unit::TestCase
  context "Excel reader" do
    setup do 
      @ds=Statsample::Excel.read(File.dirname(__FILE__)+"/test_xls.xls")
    end
    should "set the number of cases" do
      assert_equal(6,@ds.cases)
    end
    should "set correct field names" do 
      assert_equal(%w{id name age city a1},@ds.fields)
    end
    should "set a dataset equal to expected" do 
      id=[1,2,3,4,5,6].to_vector(:scale)
      name=["Alex","Claude","Peter","Franz","George","Fernand"].to_vector(:nominal)
      age=[20,23,25,nil,5.5,nil].to_vector(:scale)
      city=["New York","London","London","Paris","Tome",nil].to_vector(:nominal)
      a1=["a,b","b,c","a",nil,"a,b,c",nil].to_vector(:nominal)
      ds_exp=Statsample::Dataset.new({'id'=>id,'name'=>name,'age'=>age,'city'=>city,'a1'=>a1}, %w{id name age city a1})
      ds_exp.fields.each{|f|
        assert_equal(ds_exp[f],@ds[f])
      }
      assert_equal(ds_exp,@ds)
    end
    should "set to nil empty cells" do 
      assert_equal(nil,@ds['age'][5])
    end
  end
  context "Excel writer" do
    setup do 
      a=100.times.map{rand(100)}.to_scale
      b=(["b"]*100).to_vector
      @ds={'b'=>b, 'a'=>a}.to_dataset(%w{b a})
      tempfile=Tempfile.new("test_write.xls")
      Statsample::Excel.write(@ds,tempfile.path)
      @ds2=Statsample::Excel.read(tempfile.path)
    end
    should "return same fields as original" do
      assert_equal(@ds.fields ,@ds2.fields)
    end
    should "return same number of cases as original" do
      assert_equal(@ds.cases, @ds2.cases)
    end
    should "return same cases as original" do
      i=0
      @ds2.each_array do |row|
        assert_equal(@ds.case_as_array(i),row)
        i+=1
      end    
    end
  end
end
