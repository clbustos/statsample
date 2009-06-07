#!/usr/bin/ruby
# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/rubyss.rb'

if File.exists? './local_rakefile.rb'
	require './local_rakefile'
end
	
	
EXT1 = "ext/distributions/cdf.#{Config::CONFIG['DLEXT']}"  
EXT2 = "ext/rubyss/rubyssopt.#{Config::CONFIG['DLEXT']}"  

Hoe.spec('rubyss') do |p|
    p.version=RubySS::VERSION
  p.developer('Claudio Bustos', 'clbustos@gmail.com')
  p.spec_extras[:extensions] = ["ext/rubyss/extconf.rb","ext/distributions/extconf.rb"]
  p.extra_deps << ["gnuplot",">= 2.2"] << ["ruby-gdchart"]
  
  p.clean_globs << EXT1 << EXT2 
  %w{distributions rubyss}.each do |ext|
  	p.clean_globs << "ext/#{ext}/*.o" << "ext/#{ext}/Makefile"
  end
  p.clean_globs << "test/images/*" 
#  p.rdoc_pattern = /^(lib|bin|ext\/distributions)|txt$/
end

task :test => [EXT1, EXT2]

file EXT1 => ["ext/distributions/extconf.rb", "ext/distributions/cdf.c", "ext/distributions/cdf.h"] do       
  Dir.chdir "ext/distributions" do
    ruby "extconf.rb"
    sh "make"
  end
end


file EXT2 => ["ext/rubyss/extconf.rb", "ext/rubyss/rubyssopt.c"] do       
  Dir.chdir "ext/rubyss" do
    ruby "extconf.rb"
    sh "make"
  end
end

# vim: syntax=Ruby
