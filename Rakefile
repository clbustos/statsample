# -*- ruby -*-

require 'rubygems'
require 'hoe'
require './lib/rubyss.rb'

EXT1 = "ext/distributions/cdf.#{Hoe::DLEXT}"  
EXT2 = "ext/rubyss/rubyssopt.#{Hoe::DLEXT}"  

Hoe.new('rubyss', RubySS::VERSION) do |p|
  # p.rubyforge_name = 'rubyssx' # if different than lowercase project name
  p.developer('Claudio Bustos', 'clbustos@gmail.com')
  p.spec_extras[:extensions] = ["ext/rubyss/extconf.rb","ext/optimization/extconf.rb"]
  p.clean_globs << EXT1 << EXT2 << "ext/distributions/*.o" << "ext/distributions/Makefile" << "ext/rubyss/*.o" << "ext/rubyss/Makefile"

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
