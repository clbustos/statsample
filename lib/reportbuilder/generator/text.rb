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
        @out="#{@builder.name}\n"
        parse_cycle(@builder)
        @out << "\n"
      end
      def add_text(t)
        ws=" "*parse_level*2
        @out << ws << t << "\n"
      end
      def add_preformatted(t)
        @out << t
      end
      def add_html(t)
        # Nothing printed
      end
    end
  end
end