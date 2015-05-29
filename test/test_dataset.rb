require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleDatasetTestCase
  def setup
    @ds = Statsample::Dataset.new({ 'id' => Statsample::Vector.new([1, 2, 3, 4, 5]), 'name' => Statsample::Vector.new(%w(Alex Claude Peter Franz George)), 'age' => Statsample::Vector.new([20, 23, 25, 27, 5]),
                                    'city' => Statsample::Vector.new(['New York', 'London', 'London', 'Paris', 'Tome']),
                                    'a1' => Statsample::Vector.new(['a,b', 'b,c', 'a', nil, 'a,b,c']) }, %w(id name age city a1))
  end

  def test_basic
    assert_equal(5, @ds.cases)
    assert_equal(%w(id name age city a1), @ds.fields)
  end

  def test_fields
    @ds.fields = %w(name a1 id age city)
    assert_equal(%w(name a1 id age city), @ds.fields)
    @ds.fields = %w(id name age)
    assert_equal(%w(id name age a1 city), @ds.fields)
  end





#   def test_vector_missing_values
#     a1 = [1, nil, 3, 4, 5, nil].to_vector(:numeric)
#     a2 = [10, nil, 20, 20, 20, 30].to_vector(:numeric)
#     b1 = [nil, nil, 1, 1, 1, 2].to_vector(:numeric)
#     b2 = [2, 2, 2, nil, 2, 3].to_vector(:numeric)
#     c = [nil, 2, 4, 2, 2, 2].to_vector(:numeric)
#     ds = { 'a1' => a1, 'a2' => a2, 'b1' => b1, 'b2' => b2, 'c' => c }.to_dataset
#     mva = [2, 3, 0, 1, 0, 1].to_vector(:numeric)
#     assert_equal(mva, ds.vector_missing_values)
#   end


#   def test_vector_count_characters
#     a1 = [1, 'abcde', 3, 4, 5, nil].to_vector(:numeric)
#     a2 = [10, 20.3, 20, 20, 20, 30].to_vector(:numeric)
#     b1 = [nil, '343434', 1, 1, 1, 2].to_vector(:numeric)
#     b2 = [2, 2, 2, nil, 2, 3].to_vector(:numeric)
#     c = [nil, 2, 'This is a nice example', 2, 2, 2].to_vector(:numeric)
#     ds = { 'a1' => a1, 'a2' => a2, 'b1' => b1, 'b2' => b2, 'c' => c }.to_dataset
#     exp = [4, 17, 27, 5, 6, 5].to_vector(:numeric)
#     assert_equal(exp, ds.vector_count_characters)
#   end


#   def test_split_by_separator
#     @ds.add_vectors_by_split('a1', '_')
#     assert_equal(%w(id name age city a1 a1_a a1_b a1_c), @ds.fields)
#     assert_equal([1, 0, 1, nil, 1], @ds.col('a1_a').to_a)
#     assert_equal([1, 1, 0, nil, 1], @ds.col('a1_b').to_a)
#     assert_equal([0, 1, 0, nil, 1], @ds.col('a1_c').to_a)
#   end


  def test_crosstab_with_asignation
    v1 = %w(a a a b b b c c c).to_vector
    v2 = %w(a b c a b c a b c).to_vector
    v3 = %w(0 1 0 0 1 1 0 0 1).to_numeric
    ds = Statsample::Dataset.crosstab_by_asignation(v1, v2, v3)
    assert_equal(:object, ds['_id'].type)
    assert_equal(:numeric, ds['a'].type)
    assert_equal(:numeric, ds['b'].type)
    ev_id = %w(a b c).to_vector
    ev_a = %w(0 0 0).to_numeric
    ev_b = %w(1 1 0).to_numeric
    ev_c = %w(0 1 1).to_numeric
    ds2 = { '_id' => ev_id, 'a' => ev_a, 'b' => ev_b, 'c' => ev_c }.to_dataset
    assert_equal(ds, ds2)
  end

end
