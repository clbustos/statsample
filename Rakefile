#!/usr/bin/ruby
# -*- ruby -*-
# -*- coding: utf-8 -*-

require 'rubygems'
require 'hoe'
require './lib/statsample'
begin
	require 'hanna/rdoctask'
rescue LoadError
	require 'rake/rdoctask'
end
if File.exists? './local_rakefile.rb'
	require './local_rakefile'
end
desc 'Generate RDoc documentation'
Rake::RDocTask.new(:docs) do |rdoc|
	rdoc.rdoc_files.include('*.txt').
	exclude('Manifest.txt').
	include('lib/**/*.rb').
	exclude('lib/statistics2.rb')
	
rdoc.main="README.txt"
rdoc.title="Statsample documentation"
	rdoc.rdoc_dir="doc2"
end
desc "Ruby Lint"
task :lint do
    executable=Config::CONFIG['RUBY_INSTALL_NAME']
    Dir.glob("lib/**/*.rb") {|f|
        
        if !system %{#{executable} -cw -W2 "#{f}"} 
            puts "Error on: #{f}"
        end
    }
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

Hoe.spec('statsample') do 
	self.version=Statsample::VERSION
	self.rubyforge_name = "ruby-statsample"
	self.developer('Claudio Bustos', 'clbustos@gmail.com')
	self.extra_deps << ["spreadsheet","=0.6.4"] << ["svg-graph", ">=1.0.0"]
	self.clean_globs << "test/images/*" << "demo/item_analysis/*" << "demo/Regression"
	#  p.rdoc_pattern = /^(lib|bin|ext\/distributions)|txt$/
	self.local_rdoc_dir="doc2"
end


# vim: syntax=Ruby
