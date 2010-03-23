$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"    
rb=ReportBuilder.new do
  image("../data/sheep.jpg")
end
rb.name="Text output"
puts rb.to_text
puts rb.to_rtf
