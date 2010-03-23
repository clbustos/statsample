class ReportBuilder
  class Generator
    class Text < Generator
      PREFIX="text"
      attr_reader :toc
      attr_reader :out
      def initialize(builder, options)
        super
        @out=""
      end
      def parse
        @out="#{@builder.name}\n" unless @builder.no_title
        parse_cycle(@builder)
      end
      def text(t)
        ws=" "*((parse_level-1)*2)
        @out << ws << t << "\n"
      end
      def preformatted(t)
        @out << t
      end
      def html(t)
        # Nothing printed
      end
    end
  end
end
