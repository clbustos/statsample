class ReportBuilder
  class Generator
    class Text < Generator
      PREFIX="text"
      attr_reader :toc
      attr_reader :out
      def initialize(builder)
        super
        @out=""
      end
      def parse
        @out="Report: #{@builder.name}\n"
        parse_cycle(@builder)
        @out << "\n"
      end
      def add_text(t)
        ws=" "*parse_level*2
        @out << ws << t << "\n"
      end
      def add_text_raw(t)
        @out << t
      end
    end
  end
end