require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleExcelTestCase < Minitest::Test
  context 'Excel reader' do
    setup do
      @ds = Statsample::Excel.read(File.dirname(__FILE__) + '/fixtures/test_xls.xls')
    end
    should 'set the number of cases' do
      assert_equal(6, @ds.nrows)
    end
    should 'set correct field names' do
      assert_equal(Daru::Index.new([:id, :name, :age, :city, :a1]), @ds.vectors)
    end
    should 'set a dataset equal to expected' do
      id   = Daru::Vector.new([1, 2, 3, 4, 5, 6])
      name = Daru::Vector.new(%w(Alex Claude Peter Franz George Fernand))
      age  = Daru::Vector.new( [20, 23, 25, nil, 5.5, nil])
      city = Daru::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome', nil])
      a1   = Daru::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c', nil])
      ds_exp = Daru::DataFrame.new(
        { :id => id, :name => name, :age => age, :city => city, :a1 => a1 }, 
        order: [:id, :name, :age, :city, :a1])
      ds_exp.vectors.each{|f|
        assert_equal(ds_exp[f], @ds[f])
      }
      assert_equal(ds_exp, @ds)
    end
    should 'set to nil empty cells' do
      assert_equal(nil, @ds[:age][5])
    end
  end
  context 'Excel writer' do
    setup do
      a = Daru::Vector.new(100.times.map { rand(100) })
      b = Daru::Vector.new((['b'] * 100))
      @ds = Daru::DataFrame.new({ :b => b, :a => a })
      tempfile = Tempfile.new('test_write.xls')
      Statsample::Excel.write(@ds, tempfile.path)
      @ds2 = Statsample::Excel.read(tempfile.path)
    end
    should 'return same fields as original' do
      assert_equal(@ds.vectors, @ds2.vectors)
    end
    should 'return same index as original' do
      assert_equal(@ds.index, @ds2.index)
    end
    should 'return same cases as original' do
      i = 0
      @ds2.each_row do |row|
        assert_equal(@ds.row[i], row)
        i += 1
      end
    end
  end
end
