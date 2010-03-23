= reportbuilder

* http://ruby-statsample.rubyforge.org/reportbuilder 

== DESCRIPTION:

Report Abstract Interface. Creates text, html and rtf output, based on a common framework.

== FEATURES

* One interface, multiple outputs
* You have two interfaces:
  * Generic, based on adding objects to a ReportBuilder object
  * Fine tuning, directly operating on ReportBuilder::Generator interface

== SYNOPSIS:

* Using generic ReportBuilder#add, every object will be parsed 
  using #report_building_FORMAT, #report_building or #to_s

    require "reportbuilder"    
    rb=ReportBuilder.new
    rb.add(2) # Int#to_s used
    table=ReportBuilder::Table.new(:name=>"Table", :header=>%w{id name})
    table.row([1,"John"])
    rb.add(table) # table have a #report_building method
    rb.add("Another text") # used directly
    rb.name="Text output"
    puts rb.to_text

* Using a block, you can control directly the generator

    require "reportbuilder"    
    rb=ReportBuilder.new do
      text("2")
      section(:name=>"Section 1") do
        table(:name=>"Table", :header=>%w{id name}) do
          row([1,"John"])
        end
      end
      preformatted("Another Text")
    end
    rb.name="Html output"
    puts rb.to_html

== DEVELOPERS

If you want to give support to your class, create a method called #report_building(g), which accept a ReportBuilder::Generator as argument. If you need fine control of output according to format, append the name of format, like #report_building_html, #report_building_text.

See ReportBuilder::Generator for API and ReportBuilder::Table, ReportBuilder::Image and ReportBuilder::Section for examples of implementation. Also, Statsample package object uses report_building on almost every class.

== REQUIREMENTS:

* RMagick, only to generate text output of images (see examples/image.rb)

== INSTALL:

  sudo gem install reportbuilder

== LICENSE:

GPL-2
