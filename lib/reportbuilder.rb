require 'reportbuilder/table'
require 'reportbuilder/section'
require 'reportbuilder/toc'

require 'reportbuilder/generator'

class ReportBuilder
  attr_reader :elements
  attr_reader :name
  attr_reader :dir
  VERSION = '0.1.0'
  # Create a new Report
  def initialize(name=nil,dir=nil)
    name||="Report "+Time.new.to_s
    dir||=Dir.pwd
    @dir=dir
    @name=name
    @elements=Array.new
  end
  # Add an element to the report.
  # If parameters is an object which respond to :to_reportbuilder,
  # this method will called.
  # Otherwise, the element itself will be added
  def add(*elements)
    elements.each do |element|
      if element.respond_to?(:to_reportbuilder)
        @elements.push(element.to_reportbuilder)
      else
        @elements.push(element)
      end
    end
  end
  # Returns a Section
  def section(name)
     Section.new(name)
  end
  # Returns a Table
  def table(h=[])
      Table.new(h)
  end
  # Returns an Html output
  def to_html
    gen=Generator::Html.new(self)
    gen.parse
    gen.out
  end
  def save_html(file)
    gen=Generator::Html.new(self)
    gen.parse
    File.open(@dir+"/"+file,"wb") {|fp|
      fp.write(gen.out)
    }
  end
  # Returns a Text output
  def to_s
    gen=Generator::Text.new(self)
    gen.parse
    gen.out
  end
end
