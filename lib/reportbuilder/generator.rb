class ReportBuilder
  # Abstract class for generators.
  # A generator is a class which control the output for a builder.
  # On parse_cycle()....
  #
  class Generator
    #PREFIX="none"
    attr_reader :parse_level
    # builder is a ReportBuilder object
    def initialize(builder)
      @builder=builder
      @parse_level=0
    end
    # parse each element of the parameters
    def parse_cycle(container)
      @parse_level+=1
      container.elements.each do |element|
        method=("to_rb_"+self.class::PREFIX).intern
        if element.respond_to? method
          element.send(method, self)
        else
          add_text(element.to_s)
        end
      end
      @parse_level-=1
    end
    def add_text(t)
      raise "Implement this"
    end
  end
  class ElementGenerator
    def initialize(generator,element)
      @element=element
      @generator=generator
    end
  end
end

require 'reportbuilder/generator/text'
require 'reportbuilder/generator/html'
