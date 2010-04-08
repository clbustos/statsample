$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
require 'minitest/unit'
require 'tempfile'
require 'tmpdir'
require 'shoulda'

module MiniTest
  class Unit
    class TestCase
      include Shoulda::InstanceMethods
      extend Shoulda::ClassMethods
      include Shoulda::Assertions

    end
  end

  module Assertions
    alias :assert_raise :assert_raises unless method_defined? :assert_raise
    alias :assert_not_equal :refute_equal unless method_defined? :assert_not_equal
    alias :assert_not_same :refute_same unless method_defined? :assert_not_same
    unless method_defined? :assert_nothing_raised
      def assert_nothing_raised(msg=nil)
        msg||="Nothing should be raised, but raised %s"
        begin
          yield
          not_raised=true
        rescue Exception => e
          not_raised=false
          msg=sprintf(msg,e)
        end
        assert(not_raised,msg)
      end
    end
  end
end
MiniTest::Unit.autorun
