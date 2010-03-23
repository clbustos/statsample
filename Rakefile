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
  self.extra_deps << ["clbustos-rtf","~>0.2.1"]
  self.extra_dev_deps << ["hpricot", "~>0.8"] 
end

# vim: syntax=ruby
