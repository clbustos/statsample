$:.unshift File.expand_path("../lib/", __FILE__)

require 'statsample/version'
require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'bundler/gem_tasks'

# Setup the necessary gems, specified in the gemspec.
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

Rake::TestTask.new do |t|
  t.pattern = "test/test_*.rb"
end

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  rdoc.rdoc_files.include("README.md", "lib", "History.txt", "LICENSE.txt", "references.txt")
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
end
