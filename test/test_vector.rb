require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleTestVector < Minitest::Test
  should 'return correct histogram' do
    a = Daru::Vector.new(10.times.map { |v| v })
    hist = a.histogram(2)
    assert_equal([5, 5], hist.bin)
    3.times do |i|
      assert_in_delta(i * 4.5, hist.get_range(i)[0], 1e-9)
    end
  end
end
