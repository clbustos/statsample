require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleCodificationTestCase < Minitest::Test
  def initialize(*args)
    v1 = Daru::Vector.new(%w(run walk,run walking running sleep sleeping,dreaming sleep,dream))
    @dict = { 'run' => 'r', 'walk' => 'w', 'walking' => 'w', 'running' => 'r', 'sleep' => 's', 'sleeping' => 's', 'dream' => 'd', 'dreaming' => 'd' }
    @ds = Daru::DataFrame.new({ :v1 => v1 })
    super
  end

  def test_create_hash
    expected_keys_v1 = %w(run walk walking running sleep sleeping dream dreaming).sort
    hash = Statsample::Codification.create_hash(@ds, [:v1])
    assert_equal([:v1], hash.keys)
    assert_equal(expected_keys_v1, hash[:v1].keys.sort)
    assert_equal(expected_keys_v1, hash[:v1].values.sort)
  end

  def test_create_excel
    filename = Dir.tmpdir + '/test_excel' + Time.now.to_s + '.xls'
    # filename = Tempfile.new("test_codification_"+Time.now().to_s)
    Statsample::Codification.create_excel(@ds, ['v1'], filename)
    field = Daru::Vector.new(['v1'] * 8, name: :field)
    keys = Daru::Vector.new(%w(dream dreaming run running sleep sleeping walk walking))
    ds = Daru::DataFrame.from_excel(filename)
    assert_equal(field, ds[:field])
    assert_equal(keys, ds[:original])
    assert_equal(keys, ds[:recoded])
    hash = Statsample::Codification.excel_to_recoded_hash(filename)
    assert_equal(keys.to_a, hash[:v1].keys.sort)
    assert_equal(keys.to_a, hash[:v1].values.sort)
  end

  def test_create_yaml
    assert_raise ArgumentError do
      Statsample::Codification.create_yaml(@ds, [])
    end
    expected_keys_v1 = %w(run walk walking running sleep sleeping dream dreaming).sort
    yaml_hash = Statsample::Codification.create_yaml(@ds, [:v1])
    h = YAML.load(yaml_hash)
    assert_equal([:v1], h.keys)
    assert_equal(expected_keys_v1, h[:v1].keys.sort)
    tf = Tempfile.new('test_codification')
    yaml_hash = Statsample::Codification.create_yaml(@ds, [:v1], tf, Statsample::SPLIT_TOKEN)
    tf.close
    tf.open
    h = YAML.load(tf)
    assert_equal([:v1], h.keys)
    assert_equal(expected_keys_v1, h[:v1].keys.sort)
    tf.close(true)
  end

  def test_recodification
    expected = [['r'], %w(w r), ['w'], ['r'], ['s'], %w(s d), %w(s d)]
    assert_equal(expected, Statsample::Codification.recode_vector(@ds[:v1], @dict))
    v2 = Daru::Vector.new(['run', 'walk,dreaming', nil, 'walk,dream,dreaming,walking'])
    expected = [['r'], %w(w d), nil, %w(w d)]
    assert_equal(expected, Statsample::Codification.recode_vector(v2, @dict))
  end

  def test_recode_dataset_simple
    Statsample::Codification.recode_dataset_simple!(@ds, :v1 => @dict)
    expected_vector = Daru::Vector.new(['r', 'w,r', 'w', 'r', 's', 's,d', 's,d'])
    assert_not_equal(expected_vector, @ds[:v1])
    assert_equal(expected_vector, @ds[:v1_recoded])
  end

  def test_recode_dataset_split
    Statsample::Codification.recode_dataset_split!(@ds, :v1 => @dict)
    e = {}
    e['r'] = Daru::Vector.new([1, 1, 0, 1, 0, 0, 0])
    e['w'] = Daru::Vector.new([0, 1, 1, 0, 0, 0, 0])
    e['s'] = Daru::Vector.new([0, 0, 0, 0, 1, 1, 1])
    e['d'] = Daru::Vector.new([0, 0, 0, 0, 0, 1, 1])
    e.each { |k, expected|
      assert_equal(expected, @ds[('v1_' + k).to_sym], "Error on key #{k}")
    }
  end
end
