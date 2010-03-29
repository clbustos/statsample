require 'reportbuilder/builder'
require 'reportbuilder/table'
require 'reportbuilder/section'
require 'reportbuilder/image'

# = Report Abstract Interface.
# Creates text, html and rtf output, based on a common framework.
#
# == Use
# 
# 
# * Using generic ReportBuilder#add, every object will be parsed using #report_building_FORMAT, #report_building or #to_s
# 
#  require "reportbuilder"    
#  rb=ReportBuilder.new
#  rb.add(2) #  Int#to_s used
#  section=ReportBuilder::Section.new(:name=>"Section 1")
#  table=ReportBuilder::Table.new(:name=>"Table", :header=>%w{id name})
#  table.row([1,"John"])
#  table.hr
#  table.row([2,"Peter"])
#  
#  section.add(table) #  Section is a container for other methods
#  rb.add(section) #  table have a #report_building method
#  rb.add("Another text") #  used directly
#  rb.name="Text output"
#  puts rb.to_text
#  rb.name="Html output"
#  puts rb.to_html
# 
# * Using a block, you can control directly the builder
# 
#  require "reportbuilder"    
#  rb=ReportBuilder.new do
#   text("2")
#   section(:name=>"Section 1") do
#    table(:name=>"Table", :header=>%w{id name}) do
#     row([1,"John"])
#     hr
#     row([2,"Peter"])
#    end
#   end
#   preformatted("Another Text")
#  end
#  rb.name="Text output"
#  puts rb.to_text
#  rb.name="Html output"
#  puts rb.to_html
class ReportBuilder
  attr_reader :elements
  # Name of report
  attr_accessor :name
  # Doesn't print a title if set to true
  attr_accessor :no_title
  # ReportBuilder version
  VERSION = '1.2.1'
  
  FormatNotFound=Class.new(Exception)
  # Available formats
  def self.builder_for(format)
    format=format.to_s.downcase
    Builder.inherited_classes.find {|m| m.code.include? format} 
  end
  # Generates and optionally save the report on one function
  def self.generate(options=Hash.new, &block)
    options[:filename]||=nil
    options[:format]||="text"
    
    if options[:filename] and options[:filename]=~/\.(\w+?)$/
      options[:format]=$1
    end
    file=options.delete(:filename)
    format=options.delete(:format)
    rb=ReportBuilder.new(options)
    rb.add(block)
    begin
      builder=builder_for(format).new(rb, options)
    rescue NameError  => e
      raise FormatNotFound.new(e)
    end
    builder.parse
    out=builder.out
    unless file.nil?
      File.open(file,"wb") do |fp|
        fp.write out
      end
    else
      out
    end
  end
  # Create a new Report
  def initialize(options=Hash.new,&block)
    options[:name]||="Report "+Time.new.to_s
    @no_title=options.delete :no_title
    @name=options.delete :name 
    @options=options
    @elements=Array.new
    add(block) if block
  end
  # Add an element to the report.
  # If parameters is an object which respond to :to_reportbuilder,
  # this method will called.
  # Otherwise, the element itself will be added
  def add(element)
    @elements.push(element)
    self
  end
  # Returns an Html output
  def to_html()
    gen = Builder::Html.new(self,@options)
    gen.parse
    gen.out
  end
  # Returns a RTF output
  def to_rtf()
    gen = Builder::Rtf.new(self, @options)
    gen.parse
    gen.out
  end  
  # Save a rtf file
  def save_rtf(filename)
    gen = Builder::Rtf.new(self,@options)
    gen.parse
    gen.save(filename)
  end
  # Save an html file
  def save_html(file)
    options=@options.dup
    options[:directory]=File.dirname(file)
    gen=Builder::Html.new(self, options)
    gen.parse
    gen.save(file)
  end
  # Returns a Text output
  def to_text()
    gen=Builder::Text.new(self, @options)
    gen.parse 
    gen.out
  end
  alias_method :to_s, :to_text
end
