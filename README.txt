= reportbuilder

* http://ruby-statsample.rubyforge.org/reportbuilder 

== DESCRIPTION:

Report Abstract Interface. Creates text, html and pdf output, based on a common framework 

== FEATURES

* One interface, multiple outputs

== SYNOPSIS:

  rb=ReportBuilder.new
  rb.add("This is a text")
  table=rb.table(%w{id name})
  table.add_row([1,"Nombre"])
  table.add_hr
  rb.add(table)
  puts rb.to_text
  puts rb.to_html
  puts rb.to_pdf

== REQUIREMENTS:


== INSTALL:

  sudo gem install reportbuilder

== LICENSE:

GPL-2
