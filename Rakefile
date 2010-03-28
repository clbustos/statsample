#!/usr/bin/ruby
# -*- ruby -*-
$:.unshift(File.dirname(__FILE__)+"/lib")

require 'rubygems'
require 'hoe'
require 'reportbuilder'


Hoe.spec 'reportbuilder' do
  self.version=ReportBuilder::VERSION
  self.rubyforge_name = 'ruby-statsample'
  self.developer('Claudio Bustos', 'clbustos_at_gmail.com')
  self.url = "http://ruby-statsample.rubyforge.org/reportbuilder/"
  self.extra_deps << ["clbustos-rtf","~>0.2.1"] << ['text-table', "~>1.2"]
  self.extra_dev_deps << ["nokogiri", "~>1.4"] 
end

task :release => [:tag] do 
end

task :tag do	
  sh %(svn commit -m "Version bump: #{ReportBuilder::VERSION}")
	sh %(svn cp https://ruby-statsample.googlecode.com/svn/reportbuilder/trunk https://ruby-statsample.googlecode.com/svn/reportbuilder/tags/v#{ReportBuilder::VERSION} -m "ReportBuilder #{ReportBuilder::VERSION} tagged")
end

# vim: syntax=ruby
