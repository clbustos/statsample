require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))
require 'mocha'
class StatsampleAnalysisTestCase < MiniTest::Unit::TestCase
  context(Statsample::Analysis) do
    should "store() should create and store Statsample::Analysis::Suite" do
      Statsample::Analysis.store(:first) do
        a=1
      end
      assert(Statsample::Analysis.stored_analysis[:first])
      assert(Statsample::Analysis.stored_analysis[:first].is_a? Statsample::Analysis::Suite)
    end
    should "store last created analysis" do
      an=Statsample::Analysis.store(:first) do
        a=1
      end
      assert_equal(an,Statsample::Analysis.last)
    end
    context(Statsample::Analysis::Suite) do
      should "puts() redirect output to puts output with same arguments" do
        an=Statsample::Analysis::Suite.new(:output)
        obj=mock()
        obj.expects(:puts).with(:first,:second).once
        an.output=obj
        an.puts(:first,:second)
      end
      should "summary() should call object.summary" do
        an=Statsample::Analysis::Suite.new(:summary)
        obj=stub('summarizable',:summary=>'summary')
        assert_equal(obj.summary,an.summary(obj))
      end
      should "attach() allows to call objects on objects which respond to fields" do
        an=Statsample::Analysis::Suite.new(:summary)
        ds={'x'=>stub(:mean=>10),'y'=>stub(:mean=>12)}
        ds.expects(:fields).returns(%w{x y}).at_least_once
        an.attach(ds)
        assert_equal(10,an.x.mean)
        assert_equal(12,an.y.mean)
        assert_raise(RuntimeError) {
          an.z
        }
      end
      should "attached objects should be called LIFO" do
        an=Statsample::Analysis::Suite.new(:summary)
        ds1={'x'=>stub(:mean=>100),'y'=>stub(:mean=>120),'z'=>stub(:mean=>13)}
        ds1.expects(:fields).returns(%w{x y z}).at_least_once
        ds2={'x'=>stub(:mean=>10),'y'=>stub(:mean=>12)}
        ds2.expects(:fields).returns(%w{x y}).at_least_once
        an.attach(ds1)
        an.attach(ds2)
        assert_equal(10,an.x.mean)
        assert_equal(12,an.y.mean)        
        assert_equal(13,an.z.mean)        
      end
      
      should "detach() without arguments drop latest object" do
        an=Statsample::Analysis::Suite.new(:summary)
        ds1={'x'=>stub(:mean=>100),'y'=>stub(:mean=>120),'z'=>stub(:mean=>13)}
        ds1.expects(:fields).returns(%w{x y z}).at_least_once
        ds2={'x'=>stub(:mean=>10),'y'=>stub(:mean=>12)}        
        ds2.expects(:fields).returns(%w{x y}).at_least_once
        an.attach(ds1)
        an.attach(ds2)
        assert_equal(10,an.x.mean)
        an.detach
        assert_equal(100, an.x.mean)
      end
      should "detach() with argument drop select object" do
        an=Statsample::Analysis::Suite.new(:summary)
        ds1={'x'=>1}
        ds1.expects(:fields).returns(%w{x}).at_least_once
        ds2={'x'=>2,'y'=>3}
        ds2.expects(:fields).returns(%w{x y}).at_least_once
        ds3={'y'=>4}
        ds3.expects(:fields).returns(%w{y}).at_least_once
        
        an.attach(ds3)
        an.attach(ds2)
        an.attach(ds1)
        assert_equal(1,an.x)
        assert_equal(3,an.y)
        an.detach(ds2)
        assert_equal(4,an.y)
      end
      should "perform a simple analysis" do
        output=mock()
        output.expects(:puts).with(5.5)
        an=Statsample::Analysis.store(:simple, :output=>output) do
          ds=data_frame(:x=>c(1..10),:y=>c(1..10))
          attach(ds)
          puts x.mean
        end
        an.run
      end
      should "rnorm returns a random normal distribution vector" do
        an=Statsample::Analysis::Suite.new(:simple)
        v=an.rnorm(1000)
        assert_in_delta(0,v.mean,0.05)
        assert_in_delta(1,v.sd,0.05)
        v=an.rnorm(1000,5,10)
        assert_in_delta(5,v.mean,0.5)
        assert_in_delta(10,v.sd,0.5)
      end
    end
    context(Statsample::Analysis::SuiteReportBuilder) do
      should "puts() use add on rb object" do
        an=Statsample::Analysis::SuiteReportBuilder.new(:puts_to_add)
        an.rb.expects(:add).with(:first).twice
        an.puts(:first, :first)
      end
      should "summary() uses add on rb object" do
        an=Statsample::Analysis::SuiteReportBuilder.new(:summary_to_add)
        an.rb.expects(:add).with(:first).once
        an.summary(:first)
      end
    end
    
  end
end
