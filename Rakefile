#!/usr/bin/ruby
# -*- ruby -*-
# -*- coding: utf-8 -*-

require 'rubygems'
require 'hoe'
require './lib/statsample'

if File.exists? './local_rakefile.rb'
	require './local_rakefile'
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
	self.extra_deps << ["spreadsheet",">=0.6.4"] << ["svg-graph", ">=1.0.0"] << ["reportbuilder", ">=0.2.0"] << ["minimization", ">=0.1.0"]
	self.clean_globs << "test/images/*" << "demo/item_analysis/*" << "demo/Regression"
	#  p.rdoc_pattern = /^(lib|bin|ext\/distributions)|txt$/
end


# vim: syntax=Ruby
