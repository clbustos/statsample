module Statsample
  module Analysis
    class Suite 
      include Statsample::Shorthand
      attr_accessor :output
      attr_accessor :name
      attr_reader :block
      def initialize(name,opts=Hash.new(),&block)
        @name=name
        @block=block
        @attached=[]
        @output=opts[:output] || ::STDOUT
        
      end
      # Run the analysis, putting output on 
      def run
         @block.arity<1 ? instance_eval(&@block) : @block.call(self)
      end
      def echo(*args)
        @output.puts *args
      end
      def summary(obj)
        obj.summary
      end
      def generate(filename)
        ar=SuiteReportBuilder.new(name,&block)
        ar.generate(filename)
      end
      def to_text
        ar=SuiteReportBuilder.new(name, &block)
        ar.to_text
      end
      
      def attach(ds)
        @attached.push(ds)
      end
      def detach(ds=nil)
        if ds.nil?
          @attached.pop
        else
          @attached.delete(ds)
        end
      end
      alias :old_boxplot :boxplot
      alias :old_histogram :histogram
      alias :old_scatterplot :scatterplot

      def show_svg(svg)
        require 'tmpdir'
        fn=Dir.tmpdir+"/image_#{Time.now.to_f}.svg"
        File.open(fn,"w") {|fp| fp.write svg}
        `xdg-open '#{fn}'`
      end
      def boxplot(*args)
        show_svg(old_boxplot(*args).to_svg)
      end
      def histogram(*args)
        show_svg(old_histogram(*args).to_svg)
      end
      def scatterplot(*args)
        show_svg(old_scatterplot(*args).to_svg)
      end
      
      def method_missing(name, *args,&block)
        @attached.reverse.each do |ds|
          return ds[name.to_s] if ds.fields.include? (name.to_s)
        end
        raise "Method #{name} doesn't exists"
      end
    end
  end
end
