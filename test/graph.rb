require File.dirname(__FILE__)+"/../lib/rubyss"
require 'rubyss/dataset'
require 'ruby_to_ruby_c'
class AB
    def hola
        puts "Hola"
    end
end

src = RubyToRubyC.translator.process(ParseTree.new.parse_tree(AB))

