$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"
rb=ReportBuilder.new
rb.add(2) # Int#to_s used
section=ReportBuilder::Section.new(:name=>"Section 1")
table=ReportBuilder::Table.new(:name=>"Table", :header=>%w{id name})
table.row([1,"John"])
table.hr
table.row([2,"Peter"])

section.add(table) # Section is a container for other methods
rb.add(section) # table have a #report_building method
rb.add("Another text") # used directly

rb.name="Text output"
puts rb.to_text
rb.name="Html output"
puts rb.to_html
