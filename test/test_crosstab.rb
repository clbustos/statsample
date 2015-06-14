require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
class StatsampleCrosstabTestCase < Minitest::Test
  def initialize(*args)
    @v1 =Daru::Vector.new( %w(black blonde black black red black brown black blonde black red black blonde))
    @v2 =Daru::Vector.new( %w(woman man man woman man man man woman man woman woman man man))
    @ct = Statsample::Crosstab.new(@v1, @v2)
    super
  end

  def test_crosstab_errors
    e1 = %w(black blonde black black red black brown black blonde black)
    assert_raise ArgumentError do
      Statsample::Crosstab.new(e1, @v2)
    end
    e2 = Daru::Vector.new(%w(black blonde black black red black brown black blonde black black))

    assert_raise ArgumentError do
      Statsample::Crosstab.new(e2, @v2)
    end
    assert_nothing_raised do
      Statsample::Crosstab.new(@v1, @v2)
    end
  end

  def test_crosstab_basic
    assert_equal(Daru::Vector.new(%w(black blonde brown red)), @ct.rows_names)
    assert_equal(Daru::Vector.new(%w(man woman)), @ct.cols_names)
    assert_equal({ 'black' => 7, 'blonde' => 3, 'red' => 2, 'brown' => 1 }, @ct.rows_total)
    assert_equal({ 'man' => 8, 'woman' => 5 }, @ct.cols_total)
  end

  def test_crosstab_frequencies
    fq = @ct.frequencies
    assert_equal(8, fq.size)
    sum = fq.inject(0) { |s, x| s + x[1] }
    assert_equal(13, sum)
    fr = @ct.frequencies_by_row
    assert_equal(4, fr.size)
    assert_equal(%w(black blonde brown red), fr.keys.sort)
    fc = @ct.frequencies_by_col
    assert_equal(2, fc.size)
    assert_equal(%w(man woman), fc.keys.sort)
    assert_equal(Matrix.rows([[3, 4], [3, 0], [1, 0], [1, 1]]), @ct.to_matrix)
  end

  def test_summary
    @ct.percentage_row = true
    @ct.percentage_column = true
    @ct.percentage_total = true
    assert(@ct.summary.size > 0)
  end

  def test_expected
    v1 = Daru::Vector.new(%w(1 1 1 1 1 0 0 0 0 0))
    v2 = Daru::Vector.new(%w(0 0 0 0 0 1 1 1 1 1))
    ct = Statsample::Crosstab.new(v1, v2)
    assert_equal(Matrix[[2.5, 2.5], [2.5, 2.5]], ct.matrix_expected)
  end

  def test_crosstab_with_scale
    v1 = Daru::Vector.new(%w(1 1 1 1 1 0 0 0 0 0))
    v2 = Daru::Vector.new(%w(0 0 0 0 0 1 1 1 1 1))
    ct = Statsample::Crosstab.new(v1, v2)
    assert_equal(Matrix[[0, 5], [5, 0]], ct.to_matrix)
    assert_nothing_raised { ct.summary }
  end
end
