#!/usr/bin/ruby
# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/statsample'
begin
	require 'hanna/rdoctask'
rescue
	require 'rake/rdoctask'
end
if File.exists? './local_rakefile.rb'
	require './local_rakefile'
end
task :prim do |t|
puts "primera"
end
task :prim do |t|
puts "segunda"
end

desc 'Generate RDoc documentation'
Rake::RDocTask.new(:docs) do |rdoc|
	rdoc.rdoc_files.include('*.txt').
	exclude('Manifest.txt').
	include('lib/**/*.rb').
	exclude('lib/statistics2.rb')
	
rdoc.main="README.txt"
rdoc.title="Docu docu docu"
	rdoc.rdoc_dir="doc2"
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
	p.extra_deps << ["spreadsheet","=0.6.4"] << ["svg-graph", ">=1.0.0"]
	p.clean_globs << "test/images/*" << "demo/item_analysis/*" << "demo/Regression"
	#  p.rdoc_pattern = /^(lib|bin|ext\/distributions)|txt$/
	p.local_rdoc_dir="doc2"
end


# vim: syntax=Ruby
