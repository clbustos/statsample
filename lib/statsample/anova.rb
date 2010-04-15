module Statsample
  module Anova
    class << self
      def oneway(*args)
        OneWay.new(*args)
      end      
      def oneway_with_vectors(*args)
        OneWayWithVectors.new(*args)
      end
    end
    # = Generic Anova one-way.
    # You could enter the sum of squares or the mean squares. You
    # should enter the degrees of freedom for numerator and denominator.
    # == Usage
    #  anova=Statsample::Anova::OneWay(:ss_num=>10,:ss_den=>20, :df_num=>2, :df_den=>10, @name=>"ANOVA for....")
    class OneWay
      include GetText
       bindtextdomain("statsample")
      attr_reader :df_num, :df_den, :ss_num, :ss_den, :ms_num, :ms_den, :ms_total, :df_total, :ss_total
      # Name of ANOVA Analisys
      attr_accessor :name
      attr_accessor :name_denominator
      attr_accessor :name_numerator
      def initialize(opts=Hash.new)
        # First see if sum of squares or mean squares are entered
        raise ArgumentError, "You should set d.f." unless (opts.has_key? :df_num and opts.has_key? :df_den)
        @df_num=opts.delete :df_num
        @df_den=opts.delete :df_den
        @df_total=@df_num+@df_den
        if(opts.has_key? :ss_num and opts.has_key? :ss_den)
          @ss_num = opts.delete :ss_num
          @ss_den =opts.delete :ss_den
          @ms_num =@ss_num.quo(@df_num)
          @ms_den =@ss_den.quo(@df_den) 
        elsif (opts.has_key? :ms_num and opts.has_key? :ms_den)
          @ms_num =opts.delete :ms_num
          @ms_den =opts.delete :ms_den
          @ss_num =@ms_num * @df_num
          @ss_den =@ss_den * @df_den
        end
        @ss_total=@ss_num+@ss_den
        @ms_total=@ms_num+@ms_den
        opts_default={:name=>"ANOVA",
                      :name_denominator=>"Explained variance",
                      :name_numerator=>"Unexplained variance"}
        @opts=opts_default.merge(opts)
        opts_default.keys.each {|k|
          send("#{k}=", @opts[k])
        }
        @f_object=Statsample::Test::F.new(@ms_num,@ms_den,@df_num,@df_den)
      end
      # F value
      def f
        @f_object.f
      end
      # P-value of F test
      def probability
        @f_object.probability
      end
      # Summary of Anova analysis
      def summary
        ReportBuilder.new(:no_title=>true).add(self).to_text
      end
      def report_building(builder) #:nodoc:
        builder.section(:name=>@name) do |b|
          report_building_table(b)
        end
      end
      def report_building_table(builder) #:nodoc:
        builder.table(:name=>_("%s Table") % @name, :header=>%w{source ss df ms f p}.map {|v| _(v)}) do |t|
          t.row([@name_numerator, sprintf("%0.3f",@ss_num),   @df_num, sprintf("%0.3f",@ms_num),  sprintf("%0.3f",f), sprintf("%0.3f", probability)])
          t.row([@name_denominator, sprintf("%0.3f",@ss_den),  @df_den, sprintf("%0.3f",@ms_den), "", ""])
          t.row([_("Total"), sprintf("%0.3f",@ss_total),  @df_total, sprintf("%0.3f",@ms_total),"",""])
        end
      end

    end
    # One Way Anova with vectors
    # Example:
    #   v1=[2,3,4,5,6].to_scale
    #   v2=[3,3,4,5,6].to_scale
    #   v3=[5,3,1,5,6].to_scale
    #   anova=Statsample::Anova::OneWayWithVectors.new([v1,v2,v3])
    #   anova.f
    #   => 0.0243902439024391
    #   anova.probability
    #   => 0.975953044203438
    #   anova.sst 
    #   => 32.9333333333333
    #
    class OneWayWithVectors < OneWay
      # Show on summary Levene test
      attr_accessor :summary_levene
      # Show on summary descriptives for vectors
      attr_accessor :summary_descriptives
      def initialize(*args)
        if args[0].is_a? Array
          @vectors=args.shift
        else
          @vectors=args.find_all {|v| v.is_a? Statsample::Vector}
          opts=args.find {|v| v.is_a? Hash}
        end
        opts||=Hash.new
        opts_default={:name=>_("Anova One-Way"), 
                      :name_numerator=>"Between Groups",
                      :name_denominator=>"Within Groups",
                      :summary_descriptives=>false,
                      :summary_levene=>false}
        @opts=opts_default.merge(opts).merge(:ss_num=>ssbg, :ss_den=>sswg, :df_num=>df_bg, :df_den=>df_wg)
        super(@opts)
      end
      alias  :sst :ss_total 
      def levene
        Statsample::Test.levene(@vectors, :name=>_("Test of Homogeneity of variances (Levene)"))
      end
      # Total mean
      def total_mean
        sum=@vectors.inject(0){|a,v| a+v.sum}
        sum.quo(n)
      end
      # Sum of squares within groups
      def sswg
        @sswg||=@vectors.inject(0) {|total,vector| total+vector.ss }
      end
      # Sum of squares between groups
      def ssbg
        m=total_mean
        @vectors.inject(0) do |total,vector|
          total + (vector.mean-m).square * vector.size 
        end
      end
      # Degrees of freedom within groups
      def df_wg
        @dk_wg||=n-k
      end
      def k
        @k||=@vectors.size
      end
      # Degrees of freedom between groups 
      def df_bg
          k-1
      end
      # Total number of cases
      def n
          @vectors.inject(0){|a,v| a+v.size}
      end
      def report_building(builder) # :nodoc:
        builder.section(:name=>@name) do |s|
          if summary_descriptives
            s.table(:name=>_("Descriptives"),:header=>%w{Name N Mean SD Min Max}.map {|v| _(v)}) do |t|
              @vectors.each do |v|
                t.row [v.name, v.n_valid, "%0.4f" % v.mean, "%0.4f" %  v.sd, "%0.4f" % v.min, "%0.4f" % v.max]
              end
            end
          end
          if summary_levene
            s.parse_element(levene)
          end
          report_building_table(s)
        end
      end
    end
  end
end
