module Statsample
  module Anova
    class Contrast
      attr_reader :psi

      attr_reader :msw
      include Summarizable
      def initialize(opts=Hash.new)
        raise "Should set at least vectors options" if opts[:vectors].nil?
        @vectors=opts[:vectors]
        @c=opts[:c]
        @c1,@c2=opts[:c1], opts[:c2]
        @t_options=opts[:t_options] || {:estimate_name=>_("Psi estimate")}
        @name=opts[:name] || _("Contrast")
        @psi=nil
        @anova=Statsample::Anova::OneWayWithVectors.new(@vectors)
        @msw=@anova.msw
      end
      # Hypothesis contrast, selecting index for each constrast
      # For example, if you want to contrast x_0 against x_1 and x_2
      # you should use
      # c.contrast([0],[1,2])
      def c_by_index(c1,c2)
        contrast=[0]*@vectors.size
        c1.each {|i| contrast[i]=1.quo(c1.size)}
        c2.each {|i| contrast[i]=-1.quo(c2.size)}
        @c=contrast
        c(contrast)
      end
      def psi
        if @psi.nil?
          c(@c) if @c
          c_by_index(@c1,@c2) if (@c1 and @c2)
        end
        @psi
      end
      def confidence_interval(cl=nil)
        t_object.confidence_interval(cl)
      end
      # Hypothesis contrast, using custom values
      # Every parameter is a contrast value. You should use
      # the same number of contrast as vectors on class and the sum
      # of constrast should be 0.
      def c(args=nil)
        
        return @c if args.nil?
        @c=args
        raise "contrast number!=vector number" if args.size!=@vectors.size
        #raise "Sum should be 0" if args.inject(0) {|ac,v| ac+v}!=0
        @psi=args.size.times.inject(0) {|ac,i| ac+(args[i]*@vectors[i].mean)}
      end
      def standard_error
        sum=@vectors.size.times.inject(0) {|ac,i|
          ac+((@c[i].rationalize**2).quo(@vectors[i].size))
        } 
        Math.sqrt(@msw*sum)
      end
      alias :se :standard_error
      def df
        @vectors.inject(0) {|ac,v| ac+v.size}-@vectors.size
      end
      def t_object
        Statsample::Test::T.new(psi, se, df, @t_options)
      end
      def t
        t_object.t
      end
      def probability
        t_object.probability
      end
      def report_building(builder)
         builder.section(:name=>@name) do |s|
           s.text _("Contrast:%s") % c.join(",")
           s.parse_element(t_object)
         end
      end
    end
  end
end
