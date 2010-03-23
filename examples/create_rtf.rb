$:.unshift(File.dirname(__FILE__)+"/../lib")
require "reportbuilder"    


rb=ReportBuilder.new do
  text("First Paragraph")
  section(:name=>"Section 1") do
    section(:name=>"Section 1.1") do
      text("Paragraph inside section 1.1")
    end
    table(:name=>"Table", :header=>%w{id name}) do
      row([1,"John"])
      row([2,"Peter"])
      hr
      row([3,"John"])
      row([4,"Peter"])
      
    end
  end
  preformatted <<-EOL
def test_generate
  html=ReportBuilder.generate(:format=>:html, :name=>@title, :directory=>@tmpdir) do 
    text("hola")
  end
  doc=Hpricot(html)
  assert_equal(@title, doc.search("head/title").inner_html)
  assert_equal(@title, doc.search("body/h1").inner_html)
  assert_equal("hola", doc.search("body/p").inner_html)
end  
EOL
    text("Last paragraph")
end
rb.name="RTF output"
puts rb.to_rtf
