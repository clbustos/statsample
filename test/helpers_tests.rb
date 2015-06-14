$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/../lib/'))
$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + '/'))

require 'minitest'
require 'minitest/unit'
require 'mocha/setup'
require 'tempfile'
require 'tmpdir'
require 'shoulda'
require 'shoulda-context'
require 'fixtures/correlation_matrix'

require 'statsample'

module Minitest
  class Test
    include Shoulda::Context::Assertions
    include Shoulda::Context::InstanceMethods
    extend Shoulda::Context::ClassMethods

    def self.should_with_gsl(name, &block)
      should(name) do
        if Statsample.has_gsl?
          instance_eval(&block)
        else
          skip('Requires GSL')
        end
      end
    end
  end

  module Assertions
    def assert_similar_vector(exp, obs, delta = 1e-10, msg = nil)
      msg ||= "Different vectors #{exp} - #{obs}"
      assert_equal(exp.size, obs.size)
      exp.to_a.each_with_index {|v, i|
        assert_in_delta(v, obs[i], delta)
      }
    end

    def assert_equal_vector(exp, obs, delta = 1e-10, msg = nil)
      assert_equal(exp.size, obs.size, "Different size.#{msg}")
      exp.size.times {|i|
        assert_in_delta(exp[i], obs[i], delta, "Different element #{i}. \nExpected:\n#{exp}\nObserved:\n#{obs}.#{msg}")
      }
    end

    def assert_equal_matrix(exp, obs, delta = 1e-10, msg = nil)
      assert_equal(exp.row_size, obs.row_size, "Different row size.#{msg}")
      assert_equal(exp.column_size, obs.column_size, "Different column size.#{msg}")
      exp.row_size.times {|i|
        exp.column_size.times {|j|
          assert_in_delta(exp[i, j], obs[i, j], delta, "Different element #{i},#{j}\nExpected:\n#{exp}\nObserved:\n#{obs}.#{msg}")
        }
      }
    end
    alias_method :assert_raise, :assert_raises unless method_defined? :assert_raise
    alias_method :assert_not_equal, :refute_equal unless method_defined? :assert_not_equal
    alias_method :assert_not_same, :refute_same unless method_defined? :assert_not_same
    unless method_defined? :assert_nothing_raised
      def assert_nothing_raised(msg = nil)
        msg ||= 'Nothing should be raised, but raised %s'
        begin
          yield
          not_raised = true
        rescue Exception => e
          not_raised = false
          msg = sprintf(msg, e)
        end
        assert(not_raised, msg)
      end
    end
  end
end

MiniTest.autorun
