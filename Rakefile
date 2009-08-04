#!/usr/bin/ruby
# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/statsample'

if File.exists? './local_rakefile.rb'
	require './local_rakefile'
end


desc "Update pot/po files."
task :updatepo do
  require 'gettext/tools'
  GetText.update_pofiles("statsample", Dir.glob("{lib,bin}/**/*.{rb,rhtml}"), "statsample #{Statsample::VERSION}")
end

desc "Create mo-files"
task :makemo do
  require 'gettext/tools'
  GetText.create_mofiles()
  # GetText.create_mofiles(true, "po", "locale")  # This is for "Ruby on Rails".
end

Hoe.spec('statsample') do |p|
	p.version=Statsample::VERSION
	p.rubyforge_name = "ruby-statsample"
	p.developer('Claudio Bustos', 'clbustos@gmail.com')
	p.extra_deps << ["spreadsheet","=0.6.4"] << "svg-graph"
	p.clean_globs << "test/images/*" << "demo/item_analysis/*" << "demo/Regression"
	#  p.rdoc_pattern = /^(lib|bin|ext\/distributions)|txt$/
end


# vim: syntax=Ruby
