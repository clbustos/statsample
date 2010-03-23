$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"    
rb=ReportBuilder.new do
  text("2")
  section(:name=>"Section 1") do
    table(:name=>"Table", :header=>%w{id name}) do
      row([1,"John"])
      hr
      row([2,"Peter"])
    end
  end
  preformatted("Another Text")
end
rb.name="Text output"
puts rb.to_text
rb.name="Html output"
puts rb.to_html

