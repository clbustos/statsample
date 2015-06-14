require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleGSLTestCase < Minitest::Test
  should_with_gsl 'matrix with gsl' do
    a = Daru::Vector.new([1, 2, 3, 4, 20])
    b = Daru::Vector.new([3, 2, 3, 4, 50])
    c = Daru::Vector.new([6, 2, 3, 4, 3])
    ds = Daru::DataFrame.new({ :a => a, :b => b, :c => c })
    gsl = ds.to_matrix.to_gsl
    assert_equal(5, gsl.size1)
    assert_equal(3, gsl.size2)
    matrix = gsl.to_matrix
    assert_equal(5, matrix.row_size)
    assert_equal(3, matrix.column_size)
  end
end
