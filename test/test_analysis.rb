require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))

class StatsampleAnalysisTestCase < Minitest::Test
  context(Statsample::Analysis) do
    setup do
      Statsample::Analysis.clear_analysis
    end
    should 'store() should create and store Statsample::Analysis::Suite' do
      Statsample::Analysis.store(:first) do
        a = 1
      end
      assert(Statsample::Analysis.stored_analysis[:first])
      assert(Statsample::Analysis.stored_analysis[:first].is_a? Statsample::Analysis::Suite)
    end

    should 'ss_analysis should create an Statsample::Analysis' do
      ss_analysis(:first) { a = 1 }
    end
    should 'store last created analysis' do
      an = Statsample::Analysis.store(:first) do
        a = 1
      end
      assert_equal(an, Statsample::Analysis.last)
    end

    should 'add_to_reportbuilder() add sections to reportbuilder object' do
      rb = mock
      rb.expects(:add).with { |value| value.is_a? ReportBuilder::Section and value.name == :first }
      rb.expects(:add).with { |value| value.is_a? ReportBuilder::Section and value.name == :second }

      Statsample::Analysis.store(:first) do
        echo 'first', 'second'
      end
      Statsample::Analysis.store(:second) do
        echo 'third'
      end
      Statsample::Analysis.add_to_reportbuilder(rb, :first, :second)
    end
    should 'to_text returns the same as a normal ReportBuilder object' do
      rb = ReportBuilder.new(name: :test)
      section = ReportBuilder::Section.new(name: 'first')
      a = Daru::Vector.new([1, 2, 3])
      section.add('first')
      section.add(a)
      rb.add(section)
      exp = rb.to_text
      an = ss_analysis(:first) {
        echo 'first'
        summary(a)
      }
      obs = Statsample::Analysis.to_text(:first)

      assert_equal(exp.split("\n")[1, exp.size], obs.split("\n")[1, obs.size])
    end

    should 'run() execute all analysis by default' do
      m1 = mock
      m1.expects(:run).once
      m1.expects(:hide).once

      Statsample::Analysis.store(:first) do
        m1.run
      end
      Statsample::Analysis.store(:second) do
        m1.hide
      end

      # Should run all test
      Statsample::Analysis.run
    end

    should 'run() execute blocks specificed on parameters' do
      m1 = mock
      m1.expects(:run).once
      m1.expects(:hide).never
      Statsample::Analysis.store(:first) do
        m1.run
      end
      Statsample::Analysis.store(:second) do
        m1.hide
      end
      # Should run all test
      Statsample::Analysis.run(:first)
    end

    context(Statsample::Analysis::Suite) do
      should 'echo() uses output#puts with same arguments' do
        an = Statsample::Analysis::Suite.new(:output)
        obj = mock
        obj.expects(:puts).with(:first, :second).once
        an.output = obj
        an.echo(:first, :second)
      end
      should 'summary() should call object.summary' do
        an = Statsample::Analysis::Suite.new(:summary)
        obj = stub('summarizable', summary: 'summary')
        assert_equal(obj.summary, an.summary(obj))
      end
      should 'attach() allows to call objects on objects which respond to fields' do
        an = Statsample::Analysis::Suite.new(:summary)
        ds = { :x => stub(mean: 10), :y => stub(mean: 12) }
        ds.expects(:vectors).returns([:x, :y]).at_least_once
        an.attach(ds)
        assert_equal(10, an.x.mean)
        assert_equal(12, an.y.mean)
        assert_raise(RuntimeError) {
          an.z
        }
      end
      should 'attached objects should be called LIFO' do
        an = Statsample::Analysis::Suite.new(:summary)
        ds1 = { :x => stub(mean: 100), :y => stub(mean: 120), :z => stub(mean: 13) }
        ds1.expects(:vectors).returns([:x, :y, :z]).at_least_once
        ds2 = { :x => stub(mean: 10), :y => stub(mean: 12) }
        ds2.expects(:vectors).returns([:x, :y]).at_least_once
        an.attach(ds1)
        an.attach(ds2)
        assert_equal(10, an.x.mean)
        assert_equal(12, an.y.mean)
        assert_equal(13, an.z.mean)
      end

      should 'detach() without arguments drop latest object' do
        an = Statsample::Analysis::Suite.new(:summary)
        ds1 = { :x => stub(mean: 100), :y => stub(mean: 120), :z => stub(mean: 13) }
        ds1.expects(:vectors).returns([:x, :y, :z]).at_least_once
        ds2 = { :x => stub(mean: 10), :y => stub(mean: 12) }
        ds2.expects(:vectors).returns([:x, :y]).at_least_once
        an.attach(ds1)
        an.attach(ds2)
        assert_equal(10, an.x.mean)
        an.detach
        assert_equal(100, an.x.mean)
      end
      should 'detach() with argument drop select object' do
        an = Statsample::Analysis::Suite.new(:summary)
        ds1 = { :x => 1 }
        ds1.expects(:vectors).returns([:x]).at_least_once
        ds2 = { :x => 2, :y => 3 }
        ds2.expects(:vectors).returns([:x, :y]).at_least_once
        ds3 = { :y => 4 }
        ds3.expects(:vectors).returns([:y]).at_least_once

        an.attach(ds3)
        an.attach(ds2)
        an.attach(ds1)
        assert_equal(1, an.x)
        assert_equal(3, an.y)
        an.detach(ds2)
        assert_equal(4, an.y)
      end
      should 'perform a simple analysis' do
        output = mock
        output.expects(:puts).with(5.5)
        an = Statsample::Analysis.store(:simple, output: output) do
          ds = data_frame(x: vector(1..10), y: vector(1..10))
          attach(ds)
          echo x.mean
        end
        an.run
      end
    end
    context(Statsample::Analysis::SuiteReportBuilder) do
      should 'echo() use add on rb object' do
        an = Statsample::Analysis::SuiteReportBuilder.new(:puts_to_add)
        an.rb.expects(:add).with(:first).twice
        an.echo(:first, :first)
      end
      should 'summary() uses add on rb object' do
        an = Statsample::Analysis::SuiteReportBuilder.new(:summary_to_add)
        an.rb.expects(:add).with(:first).once
        an.summary(:first)
      end
    end
  end
end
