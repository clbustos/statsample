# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/rubyss.rb'

EXT = "ext/rubyss_ext.#{Hoe::DLEXT}"  

Hoe.new('rubyss', RubySS::VERSION) do |p|
  # p.rubyforge_name = 'rubyssx' # if different than lowercase project name
  p.developer('Claudio Bustos', 'clbustos@gmail.com')
  p.spec_extras[:extensions] = "ext/extconf.rb"      
  p.clean_globs << EXT << "ext/*.o" << "ext/Makefile"

end

task :test => EXT
file EXT => ["ext/extconf.rb", "ext/rubyss_ext.c", "ext/rubyss_ext.h"] do       
  Dir.chdir "ext" do
    ruby "extconf.rb"
    sh "make"
  end
end


# vim: syntax=Ruby
