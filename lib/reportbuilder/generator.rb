class ReportBuilder
  # Abstract class for generators.
  #   A generator is a class which control the output for a builder.
  # On parse_cycle()....
  #
  class Generator
    attr_reader :parse_level
    # builder is a ReportBuilder object
    def initialize(builder, options)
      @builder=builder
      @parse_level=0
      @options=default_options.merge(options)
      @toc=[]
      @table_n=1
      @entry_n=1
      @list_tables=[]

    end
    def default_options
      {}
    end
    # parse each element of the parameters
    def parse_cycle(container)
      @parse_level+=1
      container.elements.each do |element|
        parse_element(element)
      end
      @parse_level-=1
    end
    
    def parse_element(element)
      method=("to_reportbuilder_" + self.class::PREFIX).intern
      if element.respond_to? method
        element.send(method, self)
      elsif element.respond_to? :to_reportbuilder
        element.send(:to_reportbuilder, self)
      else
        add_text(element.to_s)
      end
    end
    
    def add_text(t)
      raise "Implement this"
    end
    def add_html(t)
      raise "Implement this"
    end
    def add_preformatted(t)
      raise "Implement this"
    end
    
    def add_toc_entry(name)
      anchor="toc_#{@entry_n}"
      @entry_n+=1
      @toc.push([anchor, name, parse_level])
      anchor
    end
    
    # Add an entry for a table
    # Returns the name of the anchor
    def add_table_entry(name)
      anchor="table_#{@table_n}"
      @table_n+=1
      @list_tables.push([anchor,name])
      anchor
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
