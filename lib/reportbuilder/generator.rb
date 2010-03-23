class ReportBuilder
  # Abstract class for generators.
  # A generator is a class which control the output for a ReportBuilder object
  #
  class Generator
    # Level of heading. See ReportBuilder::Section for using it.
    attr_reader :parse_level
    # Options for Generator. Passed by ReportBuilder class on creation
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
    # Parse the output. Could be reimplemented on subclasses
    def parse
      parse_cycle(@builder)
    end
    # Save the output of generator to a file
    def save(filename)
      File.open(filename, "wb") do |fp|
        fp.write(out)
      end
    end
    
    def default_options # :nodoc:
      Hash.new
    end
    
    # Parse each element of the container
    def parse_cycle(container)
      @parse_level+=1
      container.elements.each do |element|
        parse_element(element)
      end
      @parse_level-=1
    end    
    
    # Parse one object, using this workflow
    # * If is a block, evaluate it
    # * Use #report_building_FORMAT
    # * Use #report_building
    # * Use #to_s
    def parse_element(element)
      method=("report_building_" + self.class::PREFIX).intern
      if element.is_a? Proc
        element.arity==0 ? instance_eval(&element) : element.call(self)
      elsif element.respond_to? method
        element.send(method, self)
      elsif element.respond_to? :report_building
        element.send(:report_building, self)
      else
        text(element.to_s)
      end
    end
    # Create and parse a table. Use a block to control the table
    def table(opt=Hash.new, &block)
      parse_element(ReportBuilder::Table.new(opt,&block))
    end
    # Create and parse an image.
    def image(filename,opt=Hash.new)
      parse_element(ReportBuilder::Image.new(filename,opt))
    end
    # Create and parse an image. Use a block to insert element inside the block
    def section(opt=Hash.new, &block)
      parse_element(ReportBuilder::Section.new(opt,&block))
    end
    
    # Add a paragraph to the report
    def text(t)
      raise "Implement this"
    end
    # Add html code. Only parsed with generator which understand html 
    def html(t)
      raise "Implement this"
    end
    # Add preformatted text
    def preformatted(t)
      raise "Implement this"
    end
    # Add a TOC (Table of Contents) entry
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
