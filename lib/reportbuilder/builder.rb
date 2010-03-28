class ReportBuilder
  # Abstract Builder.
  # A builder is a class which control the output for a ReportBuilder object
  # Every object which have a #report_building() method could be
  # parsed with #parse_element method.
  class Builder
    # Level of heading. See ReportBuilder::Section for using it.
    attr_reader :parse_level
    # Options for Builder. Passed by ReportBuilder class on creation
    attr_reader :options
    # Entries for Table of Contents
    attr_reader :toc
    # Array of string with format names for the Builder.
    # For example, Html builder returns %w{html htm} and 
    # Text builde returns %w{text txt}
    def self.code
#      raise "Implement this"
    end
    def self.inherited_classes
      @@inherited_classes||=Array.new
    end
    def self.inherited(subclass)
      inherited_classes << subclass
    end
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
    # Save the output of builder to a file
    def save(filename)
      File.open(filename, "wb") do |fp|
        fp.write(out)
      end
    end
    
    def default_options # :nodoc:
      Hash.new
    end
    
    # Parse each #elements of the container
    def parse_cycle(container)
      @parse_level+=1
      container.elements.each do |element|
        parse_element(element)
      end
      @parse_level-=1
    end    
    
    # Parse one object, using this workflow
    # * If is a block, evaluate it
    # * Use #report_building_CODE, where CODE is one of the codes defined by #code
    # * Use #report_building
    # * Use #to_s
    def parse_element(element)
      methods=self.class.code.map {|m| ("report_building_"+m).intern}
      
      if element.is_a? Proc
        element.arity<1 ? instance_eval(&element) : element.call(self)
      elsif method=methods.find {|m| element.respond_to? m}
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
    # Add html code. Only parsed with builder which understand html 
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
  
  class ElementBuilder
    def initialize(builder,element)
      @element=element
      @builder=builder
    end
  end
end

require 'reportbuilder/builder/text'
require 'reportbuilder/builder/html'
require 'reportbuilder/builder/rtf'

