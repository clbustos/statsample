# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/rubyss.rb'

EXT = "ext/distributions/rubyss_ext.#{Hoe::DLEXT}"  

Hoe.new('rubyss', RubySS::VERSION) do |p|
  # p.rubyforge_name = 'rubyssx' # if different than lowercase project name
  p.developer('Claudio Bustos', 'clbustos@gmail.com')
  p.spec_extras[:extensions] = "ext/distributions/extconf.rb"      
  p.clean_globs << EXT << "ext/distributions/*.o" << "ext/distributions/Makefile"

end

task :test => EXT
file EXT => ["ext/distributions/extconf.rb", "ext/distributions/rubyss_ext.c", "ext/distributions/rubyss_ext.h"] do       
  Dir.chdir "ext/distributions" do
    ruby "extconf.rb"
    sh "make"
  end
end


# vim: syntax=Ruby
