require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))

class StatsampleTestTestCase < Minitest::Test
  def test_chi_square_matrix_with_expected
    real=Matrix[[95,95],[45,155]]
    expected=Matrix[[68,122],[72,128]]
    assert_nothing_raised do
      Statsample::Test.chi_square(real,expected)
    end
    chi=Statsample::Test.chi_square(real,expected).chi_square
    assert_in_delta(32.53,chi,0.1)

  end
  def test_chi_square_matrix_only_observed
    observed=Matrix[[20,30,40],[30,40,50],[60,70,80],[10,20,40]]
    assert_nothing_raised do
      Statsample::Test.chi_square(observed)
    end
    chi=Statsample::Test.chi_square(observed)
    assert_in_delta(9.5602, chi.chi_square, 0.0001)
    assert_in_delta(0.1444, chi.probability, 0.0001)

    assert_equal(6, chi.df)

  end

  def test_u_mannwhitney
    a=[1,2,3,4,5,6].to_scale
    b=[0,5,7,9,10,11].to_scale
    assert_equal(7.5, Statsample::Test.u_mannwhitney(a,b).u)
    assert_equal(7.5, Statsample::Test.u_mannwhitney(b,a).u)
    a=[1, 7,8,9,10,11].to_scale
    b=[2,3,4,5,6,12].to_scale
    assert_equal(11, Statsample::Test.u_mannwhitney(a,b).u)
  end


  def test_levene
    a=[1,2,3,4,5,6,7,8,100,10].to_scale
    b=[30,40,50,60,70,80,90,100,110,120].to_scale
    levene=Statsample::Test::Levene.new([a,b])
    assert_levene(levene)
  end
  def test_levene_dataset
    a=[1,2,3,4,5,6,7,8,100,10].to_scale
    b=[30,40,50,60,70,80,90,100,110,120].to_scale
    ds={'a'=>a,'b'=>b}.to_dataset
    levene=Statsample::Test::Levene.new(ds)
    assert_levene(levene)
  end
  def assert_levene(levene)
    assert_in_delta(0.778, levene.f, 0.001)
    assert_in_delta(0.389, levene.probability, 0.001)
  end

end
