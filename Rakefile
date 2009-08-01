#!/usr/bin/ruby
# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/rubyss.rb'

if File.exists? './local_rakefile.rb'
	require './local_rakefile'
end
	
	
EXT2 = "ext/rubyss/rubyssopt.#{Config::CONFIG['DLEXT']}"  


task :test => [ EXT2]

file "ext/rubyss/Makefile" => ["ext/rubyss/extconf.rb"] do |t|
    Dir.chdir "ext/rubyss" do
     system %(ruby extconf.rb)
    end

end
file EXT2 => ["ext/rubyss/Makefile", "ext/rubyss/rubyssopt.c"] do       
	puts "Compiling"
  Dir.chdir "ext/rubyss" do
    system %(make)
    end
end

Hoe.spec('rubyss') do |p|
	p.version=RubySS::VERSION
	p.rubyforge_name = "ruby-statsample"
	p.developer('Claudio Bustos', 'clbustos@gmail.com')
	p.spec_extras[:extensions] = ["ext/rubyss/extconf.rb"]
	p.extra_deps << "spreadsheet" << "svg-graph"
	p.clean_globs << EXT2 
	%w{rubyss}.each do |ext|
	p.clean_globs << "ext/#{ext}/*.o" << "ext/#{ext}/*.so" << "ext/#{ext}/Makefile"
	end
	p.clean_globs << "test/images/*" 
	#  p.rdoc_pattern = /^(lib|bin|ext\/distributions)|txt$/
end


# vim: syntax=Ruby
