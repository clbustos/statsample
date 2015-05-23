require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleCSVTestCase < Minitest::Test
  def setup
    @ds = Statsample::CSV.read('test/fixtures/test_csv.csv')
  end

  def test_read
    header = [:id, :name, :age, :city, :a1]
    data = {
      :id   => Daru::Vector.new([1, 2, 3, 4, 5, 6]),
      :name => Daru::Vector.new(%w(Alex Claude Peter Franz George Fernand)),
      :age  => Daru::Vector.new([20, 23, 25, 27, 5.5, nil]),
      :city => Daru::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome', nil]),
      :a1   => Daru::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c', nil])
    }

    ds_exp = Daru::DataFrame.new(data, order: header)

    assert_equal(6, @ds.nrows)
    assert_equal(header, @ds.vectors.to_a)

    ds_exp.vectors.each do |f|
      assert_equal(ds_exp[f], @ds[f])
    end

    assert_equal(ds_exp, @ds)
  end

  def test_nil
    assert_equal(nil, @ds[:age][5])
  end

  def test_repeated
    ds = Statsample::CSV.read('test/fixtures/repeated_fields.csv')
    assert_equal([:id, :name_1, :age_1, :city, :a1, :name_2, :age_2], ds.vectors.to_a)
    age = Daru::Vector.new([3, 4, 5, 6, nil, 8])
    assert_equal(age, ds[:age_2])
  end

  # Testing fix for SciRuby/statsample#19.
  def test_accept_scientific_notation_as_float
    ds = Statsample::CSV.read('test/fixtures/scientific_notation.csv')
    assert_equal([:x, :y], ds.vectors.to_a)
    y = [9.629587310436753e+127, 1.9341543147883677e+129, 3.88485279048245e+130]
    y.zip(ds[:y]).each do |y_expected, y_ds|
      assert_in_delta(y_expected, y_ds)
    end

  end

  def test_write
    filename = Tempfile.new('afile')
    Statsample::CSV.write(@ds, filename.path)
    ds2 = Statsample::CSV.read(filename.path)
    i = 0

    ds2.each_row do |row|
      assert_equal(@ds.row[i], row)
      i += 1
    end
  end
end
