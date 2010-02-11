require 'reportbuilder/table'
require 'reportbuilder/section'
require 'reportbuilder/generator'
require 'reportbuilder/image'

class ReportBuilder
  attr_reader :elements
  attr_reader :name
  attr_reader :dir
  VERSION = '0.2.0'
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
  def add(element)
      @elements.push(element)
  end
  # Returns a Section
  def section(options={})
    Section.new(options)
  end
  def image(filename)
    Image.new(filename)
  end
  # Returns a Table
  def table(h=[])
      Table.new(h)
  end
  # Returns an Html output
  def to_html(options={})
    gen = Generator::Html.new(self,options)
    gen.parse
    gen.out
  end
  def save_html(file, options={})
    gen=Generator::Html.new(self,options)
    gen.parse
    File.open(@dir+"/"+file,"wb") {|fp|
      fp.write(gen.out)
    }
  end
  # Returns a Text output
  def to_text(options={})
    gen=Generator::Text.new(self, options)
    gen.parse
    gen.out
  end
  alias_method :to_s, :to_text
end
