require(File.dirname(__FILE__)+'/helpers_tests.rb')

begin
  require 'rserve'
  require 'statsample/rserve_extension'

class StatsampleRserveExtensionTestCase < MiniTest::Unit::TestCase
  context "Statsample Rserve extensions" do
    setup do
      @r=Rserve::Connection.new
    end
    should "return a valid rexp for numeric vector" do
      a=100.times.map {|i| rand()>0.9 ? nil : i+rand() }.to_scale
      rexp=a.to_REXP
      assert_instance_of(rexp, Rserve::REXP::Double)
      assert_equal(rexp.to_ruby,a.data_with_nils)
      @r.assign 'a',rexp
      assert_equal(a.data_with_nils, @r.eval('a').to_ruby)
    end
    should "return a valid rserve dataframe for statsample datasets" do
      a=100.times.map {|i| rand()>0.9 ? nil : i+rand() }.to_scale
      b=100.times.map {|i| rand()>0.9 ? nil : i+rand() }.to_scale
      c=100.times.map {|i| rand()>0.9 ? nil : i+rand() }.to_scale
      ds={'a'=>a,'b'=>b,'c'=>c}.to_dataset
      rexp=ds.to_REXP
      assert_instance_of(rexp, Rserve::REXP::GenericVector)
      ret=rexp.to_ruby
      assert_equal(a.data_with_nils, ret['a']) 
      @r.assign 'df', rexp
      out_df=@r.eval('df').to_ruby
      assert_equal('data.frame', out_df.attributes['class'])
      assert_equal(['a','b','c'], out_df.attributes['names'])
      assert_equal(a.data_with_nils, out_df['a'])
    end
  end
end

rescue LoadError
  puts "Require rserve extension"
end
