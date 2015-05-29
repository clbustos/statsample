require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleTestVector < Minitest::Test
  include Statsample::Shorthand

  def setup
    @c = Statsample::Vector.new([5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99], :object)
    @c.name = 'Test Vector'
    @c.missing_values = [-99]
  end

#   def assert_counting_tokens(b)
#     assert_equal([1, 1, 0, 1, 0, nil], b['a'].to_a)
#     assert_equal([0, 1, 0, 0, 0, nil], b['b'].to_a)
#     assert_equal([0, 0, 1, 0, 0, nil], b['c'].to_a)
#     assert_equal([0, 0, 1, 1, 0, nil], b['d'].to_a)
#     assert_equal([0, 0, 0, 0, 1, nil], b[10].to_a)
#   end
  context Statsample do
    setup do
      @sample = 100
      @a = @sample.times.map { |i| (i + rand(10)) % 10 == 0 ? nil : rand(100) }.to_numeric
      @b = @sample.times.map { |i| (i + rand(10)) % 10 == 0 ? nil : rand(100) }.to_numeric
      @correct_a = []
      @correct_b = []
      @a.each_with_index do |_v, i|
        if !@a[i].nil? and !@b[i].nil?
          @correct_a.push(@a[i])
          @correct_b.push(@b[i])
        end
      end
      @correct_a = @correct_a.to_numeric
      @correct_b = @correct_b.to_numeric

      @common = lambda  do |av, bv|
        assert_equal(@correct_a, av, 'A no es esperado')
        assert_equal(@correct_b, bv, 'B no es esperado')
        assert(!av.has_missing_data?, 'A tiene datos faltantes')
        assert(!bv.has_missing_data?, 'b tiene datos faltantes')
      end
    end
    should 'return correct only_valid' do
      av, bv = Statsample.only_valid @a, @b
      av2, bv2 = Statsample.only_valid av, bv
      @common.call(av, bv)
      assert_equal(av, av2)
      assert_not_same(av, av2)
      assert_not_same(bv, bv2)
    end
    should 'return correct only_valid_clone' do
      av, bv = Statsample.only_valid_clone @a, @b
      @common.call(av, bv)
      av2, bv2 = Statsample.only_valid_clone av, bv
      assert_equal(av, av2)
      assert_same(av, av2)
      assert_same(bv, bv2)
    end
  end

#   context Statsample::Vector do
#     setup do
#       @c = Statsample::Vector.new([5, 5, 5, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99], :object)
#       @c.name = 'Test Vector'
#       @c.missing_values = [-99]
#     end

#     context 'when initializing' do
#       setup do
#         @data = (10.times.map { rand(100) }) + [nil]
#         @original = Statsample::Vector.new(@data, :numeric)
#       end
#       should '[] returns same results as R-c()' do
#         reference = [0, 4, 5, 6, 10].to_numeric
#         assert_equal(reference, Statsample::Vector[0, 4, 5, 6, 10])
#         assert_equal(reference, Statsample::Vector[0, 4..6, 10])
#         assert_equal(reference, Statsample::Vector[[0], [4, 5, 6], [10]])
#         assert_equal(reference, Statsample::Vector[[0], [4, [5, [6]]], [10]])

#         assert_equal(reference, Statsample::Vector[[0], [4, 5, 6].to_vector, [10]])
#       end
#     end

    context "new types :numeric and :object" do
      should "set default type of vector to :object" do
        v = Statsample::Vector.new [1,2,3,4,5]
        assert_equal(:object, v.type)
      end

      should "initialize Vector with :numeric type" do
        v = Statsample::Vector.new [1,2,3,4,5,nil], :numeric
        assert_equal(:numeric, v.type)
        assert_equal([1,2,3,4,5], v.valid_data)
      end

      should "show a warning when initializing with :nominal, :numeric or :ordinal" do
        assert_output(nil,"WARNING: nominal has been deprecated. Use :object instead.\n") do
          Statsample::Vector.new [1,2,3,4,5,nil,'hello'], :nominal
        end

        assert_output(nil,"WARNING: scale has been deprecated. Use :numeric instead.\n") do
          Statsample::Vector.new [1,2,3,4,nil,5], :scale
        end

        assert_output(nil,"WARNING: ordinal has been deprecated. Use :numeric instead.\n") do
          Statsample::Vector.new [1,2,3,4,5], :ordinal
        end

        assert_output(nil,"WARNING: .new_scale has been deprecated. Use .new_numeric instead.\n") do
          Statsample::Vector.new_scale 10, 1
        end
      end

      should "test that new shorthands work" do
        numeric = Statsample::Vector.new([1,2,3,4,nil,5], :numeric)
        assert_equal(numeric, [1,2,3,4,nil,5].to_numeric)
        assert_equal(numeric, [1,2,3,4,nil,5].to_vector(:numeric))

        obj = Statsample::Vector.new([1,2,3,4,'one','two'], :object)
        assert_equal(obj, [1,2,3,4,'one','two'].to_vector(:object))
      end

      should "test that old shorthands raise warnings" do
        assert_output(nil,"WARNING: to_scale has been deprecated. Use to_numeric instead.\n") do
          [1,2,3,4,nil,5].to_scale
        end
      end
    end



    should 'return correct histogram' do
      a = 10.times.map { |v| v }.to_numeric
      hist = a.histogram(2)
      assert_equal([5, 5], hist.bin)
      3.times do |i|
        assert_in_delta(i * 4.5, hist.get_range(i)[0], 1e-9)
      end
    end

    should 'raise NoMethodError when method requires numeric and vector is object' do
      @c.type = :object
      assert_raise(::NoMethodError) { @c.median }
    end


#   def test_vector_standarized_with_zero_variance
#     v1 = 100.times.map { |_i| 1 }.to_numeric
#     exp = 100.times.map { nil }.to_numeric
#     assert_equal(exp, v1.standarized)
#   end

#   def test_check_type
#     v = Statsample::Vector.new
#     v.type = :object
#     assert_raise(NoMethodError) { v.check_type(:numeric) }
#     assert(v.check_type(:object).nil?)

#     v.type = :numeric

#     assert(v.check_type(:numeric).nil?)
#     assert(v.check_type(:object).nil?)

#     v.type = :date
#     assert_raise(NoMethodError) { v.check_type(:numeric) }
#     assert_raise(NoMethodError) { v.check_type(:numeric) }
#     assert_raise(NoMethodError) { v.check_type(:object) }
# end

#   def test_add
#     a = Statsample::Vector.new([1, 2, 3, 4, 5], :numeric)
#     b = Statsample::Vector.new([11, 12, 13, 14, 15], :numeric)
#     assert_equal([3, 4, 5, 6, 7], (a + 2).to_a)
#     assert_equal([12, 14, 16, 18, 20], (a + b).to_a)
#     assert_raise ArgumentError do
#       a + @c
#     end
#     assert_raise TypeError do
#       a + 'string'
#     end
#     a = Statsample::Vector.new([nil, 1, 2, 3, 4, 5], :numeric)
#     b = Statsample::Vector.new([11, 12, nil, 13, 14, 15], :numeric)
#     assert_equal([nil, 13, nil, 16, 18, 20], (a + b).to_a)
#     assert_equal([nil, 13, nil, 16, 18, 20], (a + b.to_a).to_a)
#   end

#   def test_minus
#     a = Statsample::Vector.new([1, 2, 3, 4, 5], :numeric)
#     b = Statsample::Vector.new([11, 12, 13, 14, 15], :numeric)
#     assert_equal([-1, 0, 1, 2, 3], (a - 2).to_a)
#     assert_equal([10, 10, 10, 10, 10], (b - a).to_a)
#     assert_raise ArgumentError do
#       a - @c
#     end
#     assert_raise TypeError do
#       a - 'string'
#     end
#     a = Statsample::Vector.new([nil, 1, 2, 3, 4, 5], :numeric)
#     b = Statsample::Vector.new([11, 12, nil, 13, 14, 15], :numeric)
#     assert_equal([nil, 11, nil, 10, 10, 10], (b - a).to_a)
#     assert_equal([nil, 11, nil, 10, 10, 10], (b - a.to_a).to_a)
#   end

#   def test_sum_of_squares
#     a = [1, 2, 3, 4, 5, 6].to_vector(:numeric)
#     assert_equal(17.5, a.sum_of_squared_deviation)
#   end

#   def test_average_deviation
#     a = [1, 2, 3, 4, 5, 6, 7, 8, 9].to_numeric
#     assert_equal(20.quo(9), a.average_deviation_population)
#   end

#   def test_samples
#     srand(1)
#     assert_equal(100, @c.sample_with_replacement(100).size)
#     assert_equal(@c.valid_data.to_a.sort, @c.sample_without_replacement(15).sort)
#     assert_raise ArgumentError do
#       @c.sample_without_replacement(20)
#     end
#     @c.type = :numeric
#     srand(1)
#     assert_equal(100, @c.sample_with_replacement(100).size)
#     assert_equal(@c.valid_data.to_a.sort, @c.sample_without_replacement(15).sort)
#   end

#   def test_valid_data
#     a = Statsample::Vector.new([1, 2, 3, 4, 'STRING'])
#     a.missing_values = [-99]
#     a.add(1, false)
#     a.add(2, false)
#     a.add(-99, false)
#     a.set_valid_data
#     exp_valid_data = [1, 2, 3, 4, 'STRING', 1, 2]
#     assert_equal(exp_valid_data, a.valid_data)
#     a.add(20, false)
#     a.add(30, false)
#     assert_equal(exp_valid_data, a.valid_data)
#     a.set_valid_data
#     exp_valid_data_2 = [1, 2, 3, 4, 'STRING', 1, 2, 20, 30]
#     assert_equal(exp_valid_data_2, a.valid_data)
#   end

#   def test_set_value
#     @c[2] = 10
#     expected = [5, 5, 10, 5, 5, 6, 6, 7, 8, 9, 10, 1, 2, 3, 4, nil, -99, -99].to_vector
#     assert_equal(expected.data, @c.data)
#   end

#   def test_gsl
#     if Statsample.has_gsl?
#       a = Statsample::Vector.new([1, 2, 3, 4, 'STRING'], :numeric)

#       assert_equal(2, a.mean)
#       assert_equal(a.variance_sample_ruby, a.variance_sample)
#       assert_equal(a.standard_deviation_sample_ruby, a.sds)
#       assert_equal(a.variance_population_ruby, a.variance_population)
#       assert_equal(a.standard_deviation_population_ruby, a.standard_deviation_population)
#       assert_nothing_raised do
#         a = [].to_vector(:numeric)
#       end
#       a.add(1, false)
#       a.add(2, false)
#       a.set_valid_data
#       assert_equal(3, a.sum)
#       b = [1, 2, nil, 3, 4, 5, nil, 6].to_vector(:numeric)
#       assert_equal(21, b.sum)
#       assert_equal(3.5, b.mean)
#       assert_equal(6, b.gsl.size)
#       c = [10, 20, 30, 40, 50, 100, 1000, 2000, 5000].to_numeric
#       assert_in_delta(c.skew,     c.skew_ruby, 0.0001)
#       assert_in_delta(c.kurtosis, c.kurtosis_ruby, 0.0001)
#     end
#   end

#   def test_vector_matrix
#     v1 = %w(a a a b b b c c).to_vector
#     v2 = %w(1 3 4 5 6 4 3 2).to_vector
#     v3 = %w(1 0 0 0 1 1 1 0).to_vector
#     ex = Matrix.rows([%w(a 1 1), %w(a 3 0), %w(a 4 0), %w(b 5 0), %w(b 6 1), %w(b 4 1), %w(c 3 1), %w(c 2 0)])
#     assert_equal(ex, Statsample.vector_cols_matrix(v1, v2, v3))
#   end

#   def test_marshalling
#     v1 = (0..100).to_a.collect { |_n| rand(100) }.to_vector(:numeric)
#     v2 = Marshal.load(Marshal.dump(v1))
#     assert_equal(v1, v2)
#   end

#   def test_dup
#     v1 = %w(a a a b b b c c).to_vector
#     v2 = v1.dup
#     assert_equal(v1.data, v2.data)
#     assert_not_same(v1.data, v2.data)
#     assert_equal(v1.type, v2.type)

#     v1.type = :numeric
#     assert_not_equal(v1.type, v2.type)
#     assert_equal(v1.missing_values, v2.missing_values)
#     assert_not_same(v1.missing_values, v2.missing_values)
#     assert_equal(v1.labels, v2.labels)
#     assert_not_same(v1.labels, v2.labels)

#     v3 = v1.dup_empty
#     assert_equal([], v3.data)
#     assert_not_equal(v1.data, v3.data)
#     assert_not_same(v1.data, v3.data)
#     assert_equal(v1.type, v3.type)
#     v1.type = :numeric
#     v3.type = :object
#     assert_not_equal(v1.type, v3.type)
#     assert_equal(v1.missing_values, v3.missing_values)
#     assert_not_same(v1.missing_values, v3.missing_values)
#     assert_equal(v1.labels, v3.labels)
#     assert_not_same(v1.labels, v3.labels)
#   end

#   def test_paired_ties
#     a = [0, 0, 0, 1, 1, 2, 3, 3, 4, 4, 4].to_vector(:numeric)
#     expected = [2, 2, 2, 4.5, 4.5, 6, 7.5, 7.5, 10, 10, 10].to_vector(:numeric)
#     assert_equal(expected, a.ranked)
#   end

#   def test_dichotomize
#     a = [0, 0, 0, 1, 2, 3, nil].to_vector
#     exp = [0, 0, 0, 1, 1, 1, nil].to_numeric
#     assert_equal(exp, a.dichotomize)
#     a = [1, 1, 1, 2, 2, 2, 3].to_vector
#     exp = [0, 0, 0, 1, 1, 1, 1].to_numeric
#     assert_equal(exp, a.dichotomize)
#     a = [0, 0, 0, 1, 2, 3, nil].to_vector
#     exp = [0, 0, 0, 0, 1, 1, nil].to_numeric
#     assert_equal(exp, a.dichotomize(1))
#     a = %w(a a a b c d).to_vector
#     exp = [0, 0, 0, 1, 1, 1].to_numeric
#     assert_equal(exp, a.dichotomize)
#   end

#   def test_can_be_methods
#     a = [0, 0, 0, 1, 2, 3, nil].to_vector
#     assert(a.can_be_numeric?)
#     a = [0, 's', 0, 1, 2, 3, nil].to_vector
#     assert(!a.can_be_numeric?)
#     a.missing_values = ['s']
#     assert(a.can_be_numeric?)

#     a = [Date.new(2009, 10, 10), Date.today, '2009-10-10', '2009-1-1', nil, 'NOW'].to_vector
#     assert(a.can_be_date?)
#     a = [Date.new(2009, 10, 10), Date.today, nil, 'sss'].to_vector
#     assert(!a.can_be_date?)
#   end

#   def test_date_vector
#     a = [Date.new(2009, 10, 10), :NOW, '2009-10-10', '2009-1-1', nil, 'NOW', 'MISSING'].to_vector(:date, missing_values: ['MISSING'])

#     assert(a.type == :date)
#     expected = [Date.new(2009, 10, 10), Date.today, Date.new(2009, 10, 10), Date.new(2009, 1, 1), nil, Date.today, nil]
#     assert_equal(expected, a.date_data_with_nils)
#   end
# end
