require 'rtf'
require 'pp'
class ReportBuilder
  class Builder
    # Rtf Builder.
    # Based on ruby-rtf (http://ruby-rtf.rubyforge.org/).
    # 
    class Rtf < Builder
      # RTF::Document object.
      # See http://ruby-rtf.rubyforge.org/ for documentation
      attr_accessor :rtf
      include RTF
      # Creates a new Rtf object
      # Params:
      # * <tt>builder</tt>: A ReportBuilder::Builder object or other with same interface
      # * <tt>options</tt>: Hash of options.
      #   * <tt>:font</tt>: Font family. Default to "Times New Roman"
      #   * <tt>:font_size</tt>: Font size. Default to 20
      #   * <tt>:table_border_width</tt>
      #   * <tt>:table_hr_width</tt>
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
      
      def self.code
        %w{rtf}
      end

      
      def default_options
        
        {
          :font=>'Times New Roman',
          :font_size=>20,
          :table_border_width=>3,
          :table_hr_width=>25
        }
      end
      # Add a paragraph of text.
      def text(*args,&block)
        if args.size==1 and args[0].is_a? String and !block
          @rtf.paragraph << args[0]
        else
          @rtf.paragraph(*args,&block)
        end
      end
      # Add a header of level <tt>level</tt> with text <tt>t</tt>
      def header(level,t)
        @rtf.paragraph(@header_styles[level][:ps]) do |n1|
          n1.apply(@header_styles[level][:cs]) do |n2|
            n2.line_break
            n2 << t
            n2.line_break
          end
        end
      end
      # Add preformatted text. By default, uses Courier
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
      # Returns rtf code for report
      def out
        @rtf.to_rtf
      end
      # Save rtf file
      def save(filename)
        File.open(filename,'wb')  {|file| file.write(@rtf.to_rtf)
        }
      end
      # Do nothing on this builder 
      def html(t)
        # Nothing
      end
    end
  end
end
