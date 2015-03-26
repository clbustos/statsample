require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleBartlettSphericityTestCase < Minitest::Test
  include Statsample::Test
  context Statsample::Test::BartlettSphericity do
    setup do
      @v1 = [1, 2, 3, 4, 7, 8, 9, 10, 14, 15, 20, 50, 60, 70].to_scale
      @v2 = [5, 6, 11, 12, 13, 16, 17, 18, 19, 20, 30, 0, 0, 0].to_scale
      @v3 = [10, 3, 20, 30, 40, 50, 80, 10, 20, 30, 40, 2, 3, 4].to_scale
      # KMO: 0.490
      ds = { 'v1' => @v1, 'v2' => @v2, 'v3' => @v3 }.to_dataset
      cor = Statsample::Bivariate.correlation_matrix(ds)
      @bs = Statsample::Test::BartlettSphericity.new(cor, 14)
    end
    should 'have correct value for chi' do
      assert_in_delta(9.477, @bs.value, 0.001)
    end
    should 'have correct value for df' do
      assert_equal(3, @bs.df)
    end
    should 'have correct value for probability' do
      assert_in_delta(0.024, @bs.probability, 0.001)
    end
  end
end
