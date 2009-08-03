#!/usr/bin/ruby
# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/statsample.rb'

if File.exists? './local_rakefile.rb'
	require './local_rakefile'
end
	
Hoe.spec('statsample') do |p|
	p.version=Statsample::VERSION
	p.rubyforge_name = "ruby-statsample"
	p.developer('Claudio Bustos', 'clbustos@gmail.com')
	p.extra_deps << "spreadsheet" << "svg-graph"
	p.clean_globs << "test/images/*" 
	#  p.rdoc_pattern = /^(lib|bin|ext\/distributions)|txt$/
end


# vim: syntax=Ruby
