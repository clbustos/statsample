require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleTestVector < Minitest::Test
  include Statsample::Shorthand

  context Statsample do
    setup do
      @sample = 100
      @a = Daru::Vector.new(@sample.times.map { |i| (i + rand(10)) % 10 == 0 ? nil : rand(100) })
      @b = Daru::Vector.new(@sample.times.map { |i| (i + rand(10)) % 10 == 0 ? nil : rand(100) })
      @correct_a = []
      @correct_b = []
      @a.each_with_index do |_v, i|
        if !@a[i].nil? and !@b[i].nil?
          @correct_a.push(@a[i])
          @correct_b.push(@b[i])
        end
      end
      @correct_a = Daru::Vector.new(@correct_a)
      @correct_b = Daru::Vector.new(@correct_b)

      @common = lambda  do |av, bv|
        assert_equal(@correct_a, av, 'A no es esperado')
        assert_equal(@correct_b, bv, 'B no es esperado')
        assert(!av.has_missing_data?, 'A tiene datos faltantes')
        assert(!bv.has_missing_data?, 'b tiene datos faltantes')
      end
    end

    should 'return correct only_valid' do
      av, bv = Statsample.only_valid @a, @b
      av.reset_index!
      bv.reset_index!
      av2, bv2 = Statsample.only_valid av, bv
      @common.call(av, bv)
      assert_equal(av, av2)
      assert_not_same(av, av2)
      assert_not_same(bv, bv2)
    end

    should 'return correct only_valid_clone' do
      av, bv = Statsample.only_valid_clone @a, @b
      av.reset_index!
      bv.reset_index!
      @common.call(av, bv)
      av2, bv2 = Statsample.only_valid_clone av, bv
      assert_equal(av, av2)
      assert_same(av, av2)
      assert_same(bv, bv2)
    end

    should 'returns correct vector_cols_matrix' do
      v1 = Daru::Vector.new(%w(a a a b b b c c))
      v2 = Daru::Vector.new(%w(1 3 4 5 6 4 3 2))
      v3 = Daru::Vector.new(%w(1 0 0 0 1 1 1 0))
      ex = Matrix.rows([%w(a 1 1), %w(a 3 0), %w(a 4 0), %w(b 5 0), %w(b 6 1), %w(b 4 1), %w(c 3 1), %w(c 2 0)])
      assert_equal(ex, Statsample.vector_cols_matrix(v1, v2, v3))
    end
  end

  context Statsample::Vector do
    context 'when initializing' do
      should '.new creates a Daru::Vector internally and shows a warning' do
        assert_output(nil, "WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using that.\n") do
          data = (10.times.map { rand(100) }) + [nil]
          original = Statsample::Vector.new(@data, :numeric)
          assert_equal(true, original.kind_of?(Daru::Vector))
        end
      end

      should '[] returns same results as R-c()' do
        assert_output(nil, "WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using that.\n") do
          assert_equal(true, Statsample::Vector[1,2,3,4,5].kind_of?(Daru::Vector))
        end
      end

      should "new_numeric/new_scale creates a Daru::Vector internally and shows a warning" do
        assert_output(nil, "WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using that.\n") do
          Statsample::Vector.new_scale(4)
        end

        assert_output(nil, "WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using that.\n") do
          Statsample::Vector.new_numeric(4)
        end
      end
    end
  end

  context "new types :numeric and :object" do
    should "numerical data is automatically detected to be of type :numeric" do
      v = Statsample::Vector.new [1,2,3,4,5,nil]
      assert_equal(:numeric, v.type)
    end

    should "object data automatically detected as :object" do
      v = Statsample::Vector.new [1,2,3,4,'hello','world']
      assert_equal(:object, v.type)
    end

    should "initialize Vector with :numeric type" do
      v = Statsample::Vector.new [1,2,3,4,5,nil], :numeric
      assert_equal(:numeric, v.type)
      assert_output(nil, "WARNING: valid_data in Statsample::Vector has been deprecated in favor of only_valid in Daru::Vector. Please use that.\n") do
        assert_equal([1,2,3,4,5], v.valid_data)
      end
    end

    should "show a warning when initializing with :nominal, :numeric or :ordinal" do
      assert_output(nil,"WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using that.\nWARNING: nominal has been deprecated.\n") do
        Statsample::Vector.new [1,2,3,4,5,nil,'hello'], :nominal
      end

      assert_output(nil,"WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using that.\nWARNING: scale has been deprecated.\n") do
        Statsample::Vector.new [1,2,3,4,nil,5], :scale
      end

      assert_output(nil,"WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using that.\nWARNING: ordinal has been deprecated.\n") do
        Statsample::Vector.new [1,2,3,4,5], :ordinal
      end

      assert_output(nil,"WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using that.\n") do
        Statsample::Vector.new_scale 10, 1
      end
    end

    should "show a warning when Statsample::Vector shorthands are used" do
      numeric = Statsample::Vector.new([1,2,3,4,nil,5], :numeric)
      assert_equal(numeric, [1,2,3,4,nil,5].to_numeric)
      assert_equal(numeric, [1,2,3,4,nil,5].to_vector(:numeric))

      obj = Statsample::Vector.new([1,2,3,4,'one','two'], :object)
      assert_equal(obj, [1,2,3,4,'one','two'].to_vector(:object))
    end

    should "test that old shorthands show deprecation warnings" do
      assert_output(nil,"WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using that.\n") do
        [1,2,3,4,nil,5].to_scale
      end
    end
  end

  should 'return correct histogram' do
    a = Daru::Vector.new(10.times.map { |v| v })
    hist = a.histogram(2)
    assert_equal([5, 5], hist.bin)
    3.times do |i|
      assert_in_delta(i * 4.5, hist.get_range(i)[0], 1e-9)
    end
  end
end
