require 'reportbuilder/table'
require 'reportbuilder/section'
require 'reportbuilder/generator'
require 'reportbuilder/image'

class ReportBuilder
  attr_reader :elements
  # Name of report
  attr_reader :name
  # Doesn't print a title on true
  attr_accessor :no_title
  
  VERSION = '1.0.0'
  # Generates and optionally save the report on one function
  def self.generate(options=Hash.new, &block)
    options[:filename]||=nil
    options[:format]||="text"
    
    if options[:filename] and options[:filename]=~/\.(\w+?)$/
      options[:format]=$1
      options[:format]="text" if options[:format]=="txt"
    end
    file=options.delete(:filename)
    format=options.delete(:format).to_s
    format[0]=format[0,1].upcase
    
    
    rb=ReportBuilder.new(options)
    rb.add(block)
    generator=Generator.const_get(format.to_sym).new(rb, options)
    generator.parse
    out=generator.out
    unless file.nil?
      File.open(file,"wb") do |fp|
        fp.write out
      end
    else
      out
    end
  end
  # Create a new Report
  def initialize(options=Hash.new)
    options[:name]||="Report "+Time.new.to_s
    @no_title=options.delete :no_title
    @name=options.delete :name 
    @options=options
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
  def to_html()
    gen = Generator::Html.new(self,@options)
    gen.parse
    gen.out
  end
  # Save an html file
  def save_html(file)
    options=@options.dup
    options[:directory]=File.dirname(file)
    gen=Generator::Html.new(self, options)
    gen.parse
    gen.save(file)
  end
  # Returns a Text output
  def to_text()
    gen=Generator::Text.new(self, @options)
    gen.parse
    gen.out
  end
  alias_method :to_s, :to_text
end
