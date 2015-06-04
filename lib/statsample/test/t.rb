module Statsample
  module Test
    # A t-test is any statistical hypothesis test in which the test 
    # statistic follows a Student's t distribution, if the null 
    # hypothesis is supported
    class T
      
      class << self
        include Math
        # Test the null hypothesis that the population mean is equal to a specified value u, one uses the statistic.
        # Is the same formula used on t-test for paired sample.
        # * <tt>x</tt>: sample/differences mean
        # * <tt>u</tt>: population mean
        # * <tt>s</tt>: sample/differences standard deviation
        # * <tt>n</tt>: sample size
        def one_sample(x,u,s,n)
          (x-u)*Math::sqrt(n).quo(s)
        end
        # Test if means of two samples are different.
        # * <tt>x1</tt>: sample 1 mean
        # * <tt>x2</tt>: sample 2 mean
        # * <tt>s1</tt>: sample 1 standard deviation
        # * <tt>s2</tt>: sample 2 standard deviation
        # * <tt>n1</tt>: sample 1 size
        # * <tt>n2</tt>: sample 2 size
        # * <tt>equal_variance</tt>: true if equal_variance assumed
        #
        def two_sample_independent(x1, x2, s1, s2, n1, n2, equal_variance = false)
          num=x1-x2
          if equal_variance
            sx1x2 = sqrt(((n1-1)*s1**2 + (n2-1)*s2**2).quo(n1+n2-2))
            den   = sx1x2*sqrt(1.quo(n1)+1.quo(n2))
          else
            den=sqrt((s1**2).quo(n1) + (s2**2).quo(n2))
          end
          num.quo(den)
        end
        # Degrees of freedom for equal variance on t test
        def df_equal_variance(n1,n2)
          n1+n2-2
        end
        # Degrees of freedom for unequal variance
        # * <tt>s1</tt>: sample 1 standard deviation
        # * <tt>s2</tt>: sample 2 standard deviation
        # * <tt>n1</tt>: sample 1 size
        # * <tt>n2</tt>: sample 2 size
        # == Reference
        # * http://en.wikipedia.org/wiki/Welch-Satterthwaite_equation
        def df_not_equal_variance(s1,s2,n1,n2)
          s2_1=s1**2
          s2_2=s2**2
          num=(s2_1.quo(n1)+s2_2.quo(n2))**2
          den=(s2_1.quo(n1)**2).quo(n1-1) + (s2_2.quo(n2)**2).quo(n2-1)
          num.quo(den)
        end        
      end
      
      include Statsample::Test
      include Summarizable
      attr_reader :standard_error, :estimate, :df
      # Tails for p-value (:both, :left or :right). Default :both
      attr_accessor :tails
      # Name of F analysis
      attr_accessor :name
      attr_accessor :confidence_level
      attr_reader :t
      attr_accessor :estimate_name, :standard_error_name
      # Creates a generic t test. Use OneSample or TwoSamplesIndependent
      # classes for better summaries.
      # Parameters:
      # * estimate: estimate
      # * standard_error: standard error of estimate
      # * df: degrees of freedom
      def initialize(estimate, standard_error, df, opts=Hash.new)
        @estimate=estimate
        @standard_error=standard_error
        @df=df
        @t = @estimate / @standard_error.to_f
        opts_default={  :tails=>:both,
                        :name=>_("T Test"),
                        :estimate_name=>_("Estimate"),
                        :standard_error_name=>_("Std.Err.of Estimate"),
        :confidence_level=>0.95}
        @opts = opts_default.merge(opts)
        
        @opts.keys.each {|k|
          send("#{k}=", @opts[k]) if respond_to? k
        }
      end
      
      alias :se :standard_error
      
      def to_f
        t
      end
      
      # probability
      def probability
        p_using_cdf(Distribution::T.cdf(t, df),  tails)
      end
      
      def confidence_interval(cl=nil)
          cl||=confidence_level
          t_crit = t_critical(cl, df)
          [estimate - se*t_crit, estimate + se*t_crit]
      end
      alias :ci :confidence_interval
      
      
      def report_building(builder) #:nodoc:
        builder.section(:name=>@name) do |section|
          section.text _("%s: %0.4f | %s: %0.4f") % [@estimate_name, @estimate, @standard_error_name, se]
          report_building_t(section)
        end
      end
      def report_building_t(s)
        df_f=@df.is_a?(Integer) ? "%d" : "%0.4f"
        s.text _("t(%d) = %0.4f, p=%0.4f (%s tails)") % [df, t,probability, tails]
        s.text _("CI(%d%%): %0.4f - %0.4f") % [confidence_level*100, ci[0],ci[1]]
        
      end
      
      
      # One Sample t-test
      # == Usage
      #   a = Daru::Vector.new(1000.times.map {rand(100)})
      #   t_1=Statsample::Test::T::OneSample.new(a, {:u=>50})
      #   t_1.summary
      #
      # === Output
      #
      #  = One Sample T Test
      #  Sample mean: 48.954
      #  Population mean:50
      #  Tails: both
      #  t = -1.1573, p=0.2474, d.f=999

      class OneSample
        include Math
        include Statsample::Test
        include Summarizable
        # Options
        attr_accessor :opts
        # Name of test
        attr_accessor :name
        # Population mean to contrast
        attr_accessor :u
        # Degress of freedom
        attr_reader :df
        # Tails for probability (:both, :left or :right)
        attr_accessor :tails 
        
        # Create a One Sample T Test
        # Options:
        # * :u = Mean to compare. Default= 0
        # * :name = Name of the analysis
        # * :tails = Tail for probability. Could be :both, :left, :right
        def initialize(vector, opts=Hash.new)
          @vector=vector
          default={:u=>0, :name=>"One Sample T Test", :tails=>:both}
          @opts=default.merge(opts)
          @name=@opts[:name]
          @u=@opts[:u]
          @tails=@opts[:tails]
          @confidence_level=@opts[:confidence_level] || 0.95
          @df= @vector.n_valid-1
          @t=nil
        end        
        def t_object
          T.new(@vector.mean-u, @vector.se, @vector.n_valid-1, opts)
        end
        def t
          t_object.t
        end
        def probability
          t_object.probability
        end
        def standard_error
          t_object.standard_error
        end
        alias :se :standard_error
        def confidence_interval(cl=nil)
          t_object.confidence_interval(cl)
        end
        alias :ci :confidence_interval
        def report_building(b) # :nodoc:
          b.section(:name=>@name) {|s|
            s.text _("Sample mean: %0.4f | Sample sd: %0.4f | se : %0.4f") % [@vector.mean, @vector.sd, se]
            s.text _("Population mean: %0.4f") % u if u!=0
            t_object.report_building_t(s)
          }
        end
      end
      # Two Sample t-test.
      #
      # == Usage
      #   a = Daru::Vector.new(1000.times.map {rand(100)})
      #   b = Daru::Vector.new(1000.times.map {rand(100)})
      #   t_2=Statsample::Test::T::TwoSamplesIndependent.new(a,b)
      #   t_2.summary
      # === Output
      #  = Two Sample T Test
      #  Mean and standard deviation
      #  +----------+---------+---------+------+
      #  | Variable |    m    |   sd    |  n   |
      #  +----------+---------+---------+------+
      #  | 1        | 49.3310 | 29.3042 | 1000 |
      #  | 2        | 47.8180 | 28.8640 | 1000 |
      #  +----------+---------+---------+------+
      #  
      #  == Levene Test
      #   Levene Test
      #   F: 0.3596
      #   p: 0.5488
      #   T statistics
      #   +--------------------+--------+-----------+----------------+
      #   |        Type        |   t    |    df     | p (both tails) |
      #   +--------------------+--------+-----------+----------------+
      #   | Equal variance     | 1.1632 | 1998      | 0.2449         |
      #   | Non equal variance | 1.1632 | 1997.5424 | 0.1362         |
      #   +--------------------+--------+-----------+----------------+

      class TwoSamplesIndependent
        include Math
        include Statsample::Test
        
        include DirtyMemoize
        include Summarizable
        # Options
        attr_accessor :opts
        # Name of test
        attr_accessor :name
        # Degress of freedom (equal variance)
        attr_reader :df_equal_variance
        # Degress of freedom (not equal variance)
        attr_reader :df_not_equal_variance
        # Value of t for equal_variance
        attr_reader :t_equal_variance
        # Value of t for non-equal_variance
        attr_reader :t_not_equal_variance
        # Probability(equal variance)
        attr_reader :probability_equal_variance
        # Probability(unequal variance)
        attr_reader :probability_not_equal_variance        
        # Tails for probability (:both, :left or :right)
        attr_accessor :tails 
        # Create the object
        
        dirty_writer :tails
        dirty_memoize :t_equal_variance, :t_not_equal_variance, :probability_equal_variance, :probability_not_equal_variance, :df_equal_variance, :df_not_equal_variance

        # Create a Two Independent T Test
        # Options:
        # * :name = Name of the analysis
        # * :tails = Tail for probability. Could be :both, :left, :right        
        def initialize(v1, v2, opts=Hash.new)
          @v1=v1
          @v2=v2
          default={:u=>0, :name=>"Two Sample T Test",  :tails=>:both}
          @opts=default.merge(opts)
          @name=@opts[:name]
          @tails=@opts[:tails]          
        end        
       
        # Set t and probability for given u
        def compute
          @t_equal_variance= T.two_sample_independent(@v1.mean, @v2.mean, @v1.sd, @v2.sd, @v1.n_valid, @v2.n_valid,true)
          
          @t_not_equal_variance= T.two_sample_independent(@v1.mean, @v2.mean, @v1.sd, @v2.sd, @v1.n_valid, @v2.n_valid, false)

          @df_equal_variance=T.df_equal_variance(@v1.n_valid, @v2.n_valid)
          @df_not_equal_variance=T.df_not_equal_variance(@v1.sd, @v2.sd, @v1.n_valid, @v2.n_valid)
          
          @probability_equal_variance = p_using_cdf(Distribution::T.cdf(@t_equal_variance, @df_equal_variance), tails)
          
          @probability_not_equal_variance = p_using_cdf(Distribution::T.cdf(@t_not_equal_variance, @df_not_equal_variance), tails)

        end
        # Cohen's d is a measure of effect size. Its defined as the difference between two means divided by a standard deviation for the data
        def d
          n1=@v1.n_valid
          n2=@v2.n_valid
          num=@v1.mean-@v2.mean
          den=Math::sqrt( ((n1-1)*@v1.sd+(n2-1)*@v2.sd).quo(n1+n2))
          num.quo(den)
        end
        
        def report_building(b) # :nodoc:
          b.section(:name=>@name) {|g|
            g.table(:name=>_("Mean and standard deviation"), :header=>[_("Variable"), _("mean"), _("sd"),_("n")]) {|t|
              t.row([@v1.name,"%0.4f" % @v1.mean,"%0.4f" % @v1.sd, @v1.n_valid])
              t.row([@v2.name,"%0.4f" % @v2.mean,"%0.4f" % @v2.sd, @v2.n_valid])
            }
            g.parse_element(Statsample::Test.levene([@v1,@v2],:name=>_("Levene test for equality of variances")))
            
            g.table(:name=>_("T statistics"),:header=>["Type","t","df", "p (#{tails} tails)"].map{|v| _(v)}) {|t|
              t.row([_("Equal variance"), "%0.4f" % t_equal_variance, df_equal_variance, "%0.4f" % probability_equal_variance])
              t.row([_("Non equal variance"), "%0.4f" % t_not_equal_variance, "%0.4f" % df_not_equal_variance, "%0.4f" % probability_not_equal_variance])
            }
            g.table(:name=>_("Effect size")) do |t|
              t.row ['x1-x2', "%0.4f" % (@v1.mean-@v2.mean)]
              t.row ['d', "%0.4f" % d]
            end
          }
        end
      end      
    end
  end
end
