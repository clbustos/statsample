gem 'clbustos-rtf'
require 'rtf'

class ReportBuilder
  class Generator
    # Rtf Generator.
    # Based on ruby-rtf (http://ruby-rtf.rubyforge.org/)
    # 
    class Rtf < Generator
      PREFIX="rtf"
      # RTF::Document object.
      # See http://ruby-rtf.rubyforge.org/ for documentation
      attr_accessor :rtf
      include RTF
      def initialize(builder, options)
        super
        @font=Font.new(Font::ROMAN, @options[:font])
        
        @rtf = Document.new(@font)
        @pre_char = CharacterStyle.new
        
        @pre_char.font = Font.new(Font::MODERN, 'Courier')
        @pre_char.font_size=@options[:font_size]
        
        @pre_par  = ParagraphStyle.new
        
        @header_styles=Hash.new {|h,k|
          cs=CharacterStyle.new
          cs.font=@font
          cs.font_size=@options[:font_size]+(8-k)*2
          cs.bold=true
          ps=ParagraphStyle.new
          ps.justification = ParagraphStyle::CENTER_JUSTIFY
          h[k]={:cs=>cs, :ps=>ps}
        }
        
      end
      def default_options
        
        {
          :font=>'Times New Roman',
          :font_size=>20,
          :table_border_width=>3,
          :table_hr_width=>25
        }
      end
      def text(*args,&block)
        if args.size==1 and args[0].is_a? String and !block
          @rtf.paragraph << args[0]
        else
          @rtf.paragraph(*args,&block)
        end
      end
      def header(level,t)
        @rtf.paragraph(@header_styles[level][:ps]) do |n1|
          n1.apply(@header_styles[level][:cs]) do |n2|
            n2 << t
          end
        end
      end
      def preformatted(t)
        @rtf.paragraph(@pre_par) do |n1|
          n1.apply(@pre_char) do |n2|
            t.split("\n").each do |line|
              n2 << line
              n2.line_break
            end
          end
        end
        
      end
      def image(filename)
        raise "Not implemented on RTF::Document. Use gem install thecrisoshow-ruby-rtf for support" unless @rtf.respond_to? :image
        @rtf.image(filename)
      end
      def out
        @rtf.to_rtf
      end
      def save(filename)
        File.open(filename,'wb')  {|file| file.write(@rtf.to_rtf)
        }
      end
    end
  end
end
