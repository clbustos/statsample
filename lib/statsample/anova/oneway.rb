module Statsample
  module Anova
    # = Generic Anova one-way.
    # You could enter the sum of squares or the mean squares. You
    # should enter the degrees of freedom for numerator and denominator.
    # == Usage
    #  anova=Statsample::Anova::OneWay(:ss_num=>10,:ss_den=>20, :df_num=>2, :df_den=>10, @name=>"ANOVA for....")
    class OneWay
      include Summarizable
      attr_reader :df_num, :df_den, :ss_num, :ss_den, :ms_num, :ms_den, :ms_total, :df_total, :ss_total
      # Name of ANOVA Analisys
      attr_accessor :name
      attr_accessor :name_denominator
      attr_accessor :name_numerator
      def initialize(opts=Hash.new)
        @name=@name_numerator=@name_denominator=nil
        
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
                      :name_denominator=>_("Explained variance"),
                      :name_numerator=>_("Unexplained variance")}
        @opts=opts_default.merge(opts)
        opts.keys.each {|k|
          send("#{k}=", @opts[k]) if self.respond_to? "#{k}="
        }
        @f_object=Statsample::Test::F.new(@ms_num, @ms_den, @df_num,@df_den)
      end
      # F value
      def f
        @f_object.f
      end
      # P-value of F test
      def probability
        @f_object.probability
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
    #   v1 = Daru::Vector.new([2,3,4,5,6])
    #   v2 = Daru::Vector.new([3,3,4,5,6])
    #   v3 = Daru::Vector.new([5,3,1,5,6])
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
      # Show on summary of contrasts
      attr_accessor :summary_contrasts
      # Array with stored contrasts
      attr_reader :contrasts
      
      def initialize(*args)
        if args[0].is_a? Array
          @vectors = args.shift
        else
          @vectors = args.find_all {|v| v.is_a? Daru::Vector}
          opts     = args.find {|v| v.is_a? Hash}
        end
        opts||=Hash.new
        opts_default={:name=>_("Anova One-Way"), 
                      :name_numerator=>_("Between Groups"),
                      :name_denominator=>_("Within Groups"),
                      :summary_descriptives=>false,
                      :summary_levene=>true,
                      :summary_contrasts=>true
        }
        @opts=opts_default.merge(opts).merge(:ss_num=>ssbg, :ss_den=>sswg, :df_num=>df_bg, :df_den=>df_wg)
        @contrasts=[]
        super(@opts)
      end
      alias :sst :ss_total 
      alias :msb :ms_num
      alias :msw :ms_den
      
      # Generates and store a contrast.
      # Options should be provided as a hash
      # [:c]=>contrast vector
      # [:c1 - :c2]=>index for automatic construction of contrast
      # [:name]=>contrast name
      
      def contrast(opts=Hash.new)
        name=opts[:name] || _("Contrast for %s") % @name
        opts=opts.merge({:vectors=>@vectors, :name=>name})
        c=Statsample::Anova::Contrast.new(opts)
        @contrasts.push(c)
        c
      end
      
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
          if summary_contrasts and @contrasts.size>0

            @contrasts.each do |c|
              s.parse_element(c)
            end
          end
          
        end
      end
    end
  end
end
