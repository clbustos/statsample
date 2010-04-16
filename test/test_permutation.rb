require(File.dirname(__FILE__)+'/helpers_tests.rb')


class StatsamplePermutationTestCase < MiniTest::Unit::TestCase
  context Statsample::Permutation do
    should "initialize with number" do
      per1=Statsample::Permutation.new(2)
      exp1=[[0,1],[1,0]]
      assert_equal(exp1,per1.permutations)
      per2=Statsample::Permutation.new(3)
      exp2=[[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]
      assert_equal(exp2,per2.permutations)
    end
    should "initialize with simple array" do
      per1=Statsample::Permutation.new(%w{a b})
      exp1=[['a','b'],['b','a']]
      assert_equal(exp1,per1.permutations)
      per2=Statsample::Permutation.new(%w{a b c})
      exp2=[%w{a b c},%w{a c b},%w{b a c} ,%w{b c a},%w{c a b},%w{c b a}]
      assert_equal(exp2,per2.permutations)
    end
    should "initialize with Statsample::Vector" do
      per2=Statsample::Permutation.new(%w{a b c}.to_vector)
      exp2=[%w{a b c},%w{a c b},%w{b a c} ,%w{b c a},%w{c a b},%w{c b a}]
      assert_equal(exp2, per2.permutations)
    end
      
    should "calculate correct number of total permutations without repetitions" do
      per1=Statsample::Permutation.new(4)
      assert_equal(24,per1.permutation_number)      
    end
    should "calculate correct number of total permutations with repetitions" do
      per2=Statsample::Permutation.new([1,1,1,0,0,0])
      assert_equal(20,per2.permutation_number)
    end
    should "initialize with array repeated" do 
      per1=Statsample::Permutation.new([0,0,1,1])
      exp1=[[0,0,1,1],[0,1,0,1],[0,1,1,0],[1,0,0,1],[1,0,1,0],[1,1,0,0]]
      assert_equal(exp1,per1.permutations)
    end
  end
end
