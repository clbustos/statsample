require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))
class StatsampleTimeSeriesPacfTestCase < MiniTest::Unit::TestCase
  context(Statsample::TimeSeries) do
    include Statsample::TimeSeries
    setup do
      @ts = (1..20).map { |x| x * 10 }.to_ts
      #setting up a proc to get a closure for pacf calling with variable lags and methods
      @pacf_proc =->(k, method) { @ts.pacf(k, method) }
    end

    should "return correct correct pacf size for lags = 5" do
      assert_equal @pacf_proc.call(5, 'yw').size, 6 
      assert_equal @pacf_proc.call(5, 'mle').size, 6
      #first element is 1.0
    end

    should "return correct correct pacf size for lags = 10" do
      assert_equal @pacf_proc.call(10, 'yw').size, 11 
      assert_equal @pacf_proc.call(10, 'mle').size, 11
      #first element is 1.0
    end

    should "have first element as 1.0" do
      assert_equal @pacf_proc.call(10, 'yw')[0], 1.0
      assert_equal @pacf_proc.call(10, 'mle')[0], 1.0
    end

    should "give correct pacf results for unbiased yule-walker" do
      result_10 = [1.0, 0.8947368421052632, -0.10582010582010604, -0.11350188273265083, -0.12357534824820737, -0.13686534216335522, -0.15470588235294147, -0.17938011883732036, -0.2151192288178601, -0.2707082833133261, -0.3678160919540221]
      result_5 = [1.0, 0.8947368421052632, -0.10582010582010604, -0.11350188273265083, -0.12357534824820737, -0.13686534216335522]
      assert_equal @pacf_proc.call(10, 'yw'), result_10
      assert_equal @pacf_proc.call(5, 'yw'), result_5

      #Checking for lag = (1..10)
      1.upto(10) do |i|
        assert_equal @pacf_proc.call(i, 'yw'), result_10[0..i]
      end
    end

    should "give correct pacf results for mle yule-walker" do
      result_10 = [1.0, 0.85, -0.07566212829370711, -0.07635069706072706, -0.07698628638512295, -0.07747034005560738, -0.0776780981161499, -0.07744984679625189, -0.0765803323191094, -0.07480650005932366, -0.07179435184923755]
      result_5 = [1.0, 0.85, -0.07566212829370711, -0.07635069706072706, -0.07698628638512295, -0.07747034005560738]
      assert_equal @pacf_proc.call(10, 'mle'), result_10
      assert_equal @pacf_proc.call(5, 'mle'), result_5

      #Checking for lag = (1..10)
      1.upto(10) do |i|
        assert_equal @pacf_proc.call(i, 'mle'), result_10[0..i]
      end
    end
  end
end
