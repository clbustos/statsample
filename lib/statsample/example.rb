module Statsample
  # Class to provide examples
  class Example
    @@examples={}
    def self.examples
      @@examples
    end
    attr_accessor :rb
    def self.of(name, &block)
      @@examples[name]=new(name)
      @@examples[name].instance_exec(&block)
      @@examples[name]
    end
    def initialize(name)
      @name=name
      @rb=ReportBuilder.new(:name=>@name)
    end
  end
end
