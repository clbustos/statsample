#!/usr/bin/ruby
# -*- ruby -*-
# -*- coding: utf-8 -*-
$:.unshift(File.dirname(__FILE__)+'/lib/')

require 'rubygems'
require 'statsample'
require 'hoe'
require 'rdoc'

Hoe.plugin :git
Hoe.plugin :doofus
desc "Ruby Lint"
task :lint do
  executable=Config::CONFIG['RUBY_INSTALL_NAME']
  Dir.glob("lib/**/*.rb") {|f|
    if !system %{#{executable} -w -c "#{f}"} 
        puts "Error on: #{f}"
    end
  }
end

task :release do
system %{git push origin master}
end

task "clobber_docs" do
  # Only to omit warnings
end
desc "Update pot/po files."
task "gettext:updatepo" do
  require 'gettext/tools'
  GetText.update_pofiles("statsample", Dir.glob("{lib,bin}/**/*.{rb,rhtml}"), "statsample #{Statsample::VERSION}")
end

desc "Create mo-files"
task "gettext:makemo" do
  require 'gettext/tools'
  GetText.create_mofiles()
  # GetText.create_mofiles(true, "po", "locale")  # This is for "Ruby on Rails".
end

h=Hoe.spec('statsample') do 
  self.version=Statsample::VERSION
  #self.testlib=:minitest
	self.rubyforge_name = "ruby-statsample"
	self.developer('Claudio Bustos', 'clbustos@gmail.com')
	self.extra_deps << ["spreadsheet","~>0.6.5"] <<  ["reportbuilder", "~>1.4"] << ["minimization", "~>0.2.0"] << ["fastercsv", ">0"] << ["dirty-memoize", "~>0.0"] << ["extendmatrix","~>0.3.1"] << ["statsample-bivariate-extension", ">0"] << ["rserve-client", "~>0.2.5"] << ["rubyvis", "~>0.5"] << ["distribution", "~>0.6"]
  
	self.extra_dev_deps << ["hoe","~>0"] << ["shoulda","~>0"] << ["minitest", "~>2.0"] << ["rserve-client", "~>0"] << ["gettext", "~>0"] << ["mocha", "~>0"] << ["hoe-git", "~>0"]
  
  self.clean_globs << "test/images/*" << "demo/item_analysis/*" << "demo/Regression"
  self.post_install_message = <<-EOF
***************************************************
Thanks for installing statsample.

On *nix, you could install statsample-optimization
to retrieve gems gsl, statistics2 and a C extension
to speed some methods.

  $ sudo gem install statsample-optimization

On Ubuntu, install  build-essential and libgsl0-dev 
using apt-get. Compile ruby 1.8 or 1.9 from 
source code first.

  $ sudo apt-get install build-essential libgsl0-dev


*****************************************************
  EOF
	self.need_rdoc=false
end

if Rake.const_defined?(:RDocTask)
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

end
desc 'Publish rdocs with analytics support'
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
