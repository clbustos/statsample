#!/usr/bin/ruby
# -*- ruby -*-
# -*- coding: utf-8 -*-
$:.unshift(File.dirname(__FILE__)+'/lib/')

require 'rubygems'
require 'hoe'
require './lib/statsample'
Hoe.plugin :git

desc "Ruby Lint"
task :lint do
  executable=Config::CONFIG['RUBY_INSTALL_NAME']
  Dir.glob("lib/**/*.rb") {|f|
    if !system %{#{executable} -w -c "#{f}"} 
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

h=Hoe.spec('statsample') do 
  self.version=Statsample::VERSION
  #self.testlib=:minitest
	self.rubyforge_name = "ruby-statsample"
	self.developer('Claudio Bustos', 'clbustos@gmail.com')
	self.extra_deps << ["spreadsheet","~>0.6.0"] << ["svg-graph", "~>1.0"] << ["reportbuilder", "~>1.0"] << ["minimization", "~>0.2.0"] << ["fastercsv"] << ["dirty-memoize", "~>0.0"] << ["statistics2", "~>0.54"]
	self.clean_globs << "test/images/*" << "demo/item_analysis/*" << "demo/Regression"
	self.need_rdoc=false
end

Rake::RDocTask.new(:docs) do |rd|
  rd.main = h.readme_file
  rd.options << '-d' if (`which dot` =~ /\/dot/) unless
    ENV['NODOT'] || Hoe::WINDOZE
  rd.rdoc_dir = 'doc'
  
  rd.rdoc_files.include("lib/**/*.rb")
  rd.rdoc_files += h.spec.extra_rdoc_files
  rd.rdoc_files.reject! {|f| f=="Manifest.txt"}
  title = h.spec.rdoc_options.grep(/^(-t|--title)=?$/).first
  if title then
    rd.options << title
  
    unless title =~ /\=/ then # for ['-t', 'title here']
    title_index = spec.rdoc_options.index(title)
    rd.options << spec.rdoc_options[title_index + 1]
    end
  else
    title = "#{h.name}-#{h.version} Documentation"
    title = "#{h.rubyforge_name}'s " + title if h.rubyforge_name != h.name
    rd.options << '--title' << title
  end
end


desc 'publicar a rdocs con analytics'
task :publicar_docs => [:clean, :docs] do
  ruby %{agregar_adsense_a_doc.rb}
  path = File.expand_path("~/.rubyforge/user-config.yml")
  config = YAML.load(File.read(path))
  host = "#{config["username"]}@rubyforge.org"
  
  remote_dir = "/var/www/gforge-projects/#{h.rubyforge_name}/#{h.remote_rdoc_dir
  }"
  local_dir = h.local_rdoc_dir
  Dir.glob(local_dir+"/**/*") {|file|
    sh %{chmod 755 #{file}}
  }
  sh %{rsync #{h.rsync_args} #{local_dir}/ #{host}:#{remote_dir}}
end
# vim: syntax=Ruby
