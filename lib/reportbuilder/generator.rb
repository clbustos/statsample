class ReportBuilder
  # Abstract class for generators.
  # A generator is a class which control the output for a ReportBuilder object
  #
  
  #
  class Generator
    attr_reader :parse_level
    # builder is a ReportBuilder object
    attr_reader :options
    def initialize(builder, options)
      @builder=builder
      @parse_level=0
      @options=default_options.merge(options)
      @toc=[]
      @table_n=1
      @entry_n=1
      @list_tables=[]

    end
    def parse
      parse_cycle(@builder)
    end
    
    def save(filename)
      File.open(filename, "wb") do |fp|
        fp.write(out)
      end
    end
    
    def default_options # :nodoc:
      Hash.new
    end
    # parse each element of the parameters
    def parse_cycle(container)
      @parse_level+=1
      container.elements.each do |element|
        parse_element(element)
      end
      @parse_level-=1
    end
    # Parse one element
    def parse_element(element)
      method=("to_reportbuilder_" + self.class::PREFIX).intern
      if element.is_a? Proc
        element.arity==0 ? instance_eval(&element) : element.call(self)
      elsif element.respond_to? method
        element.send(method, self)
      elsif element.respond_to? :to_reportbuilder
        element.send(:to_reportbuilder, self)
      else
        text(element.to_s)
      end
    end
    def table(opt=Hash.new, &block)
      parse_element(ReportBuilder::Table.new(opt,&block))
    end
    def image(filename,opt=Hash.new)
      parse_element(ReportBuilder::Image.new(filename,opt))
    end
    
    def text(t)
      raise "Implement this"
    end
    def html(t)
      raise "Implement this"
    end
    def preformatted(t)
      raise "Implement this"
    end
    # Add a TOC (Table of Contents) Entry
    # Return the name of anchor
    def toc_entry(name)
      anchor="toc_#{@entry_n}"
      @entry_n+=1
      @toc.push([anchor, name, parse_level])
      anchor
    end

    # Add an entry for  table index.
    # Returns the name of the anchor
    def table_entry(name)
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
