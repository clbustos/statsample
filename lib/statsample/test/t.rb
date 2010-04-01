module Statsample
  module Test
    module T
      class << self
        include Math
        # Test the null hypothesis that the population mean is equal to a specified value u, one uses the statistic.
        # Is the same formula used on t-test for paired sample.
        # * <tt>x</tt>: sample/differences mean
        # * <tt>u</tt>: population mean
        # * <tt>s</tt>: sample/differences standard deviation
        # * <tt>n</tt>: sample size
        def one_sample(x,u,s,n)
          (x-u).quo(s.quo(Math::sqrt(n)))
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
         # Degrees of freedom for equal variance
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
      # One Sample t-test
      # == Usage
      #   a=1000.times.map {rand(100)}.to_scale
      #   t_1=Statsample::Test::T::OneSample.new(a, {:u=>50})
      #   t_1.summary
      class OneSample
        include Math
        include Statsample::Test
        include DirtyMemoize
        # Options
        attr_accessor :opts
        # Name of test
        attr_accessor :name
        # Population mean to contrast
        attr_accessor :u
        # Degress of freedom
        attr_reader :df
        # Value of t
        attr_reader :t
        # Probability
        attr_reader :probability
        # Tails for probability (:both, :left or :right)
        attr_accessor :tails 
        
        dirty_writer :u, :tails
        dirty_memoize :t, :probability
        
        def initialize(vector, opts=Hash.new)
          @vector=vector
          default={:u=>0, :name=>"One Sample T Test", :tails=>:both}
          @opts=default.merge(opts)
          @name=@opts[:name]
          @u=@opts[:u]
          @tails=@opts[:tails]
          @df= @vector.n_valid-1
          @t=nil
        end        
       
        
        # Set t and probability for given u
        def compute
          @t  = T.one_sample(@vector.mean, @u, @vector.sd, @vector.n_valid)
          @probability = p_using_cdf(Distribution::T.cdf(@t, @df), tails)
        end
        # Presents summary of analysis
        # 
        def summary
          ReportBuilder.new(:no_title=>true).add(self).to_text
        end
        def report_building(b) # :nodoc:
          b.section(:name=>@name) {|s|
            s.text "Sample mean: #{@vector.mean}"
            s.text "Population mean:#{u}"
            s.text "Tails: #{tails}"
            s.text sprintf("t = %0.4f, p=%0.4f, d.f=%d", t, probability, df)
          }
        end
      end
      # Two Sample t-test.
      #
      # == Usage
      #   a=1000.times.map {rand(100)}.to_scale
      #   b=1000.times.map {rand(100)}.to_scale
      #   t_2=Statsample::Test::T::OneSample.new(a,b)
      #   t_2.summary
      
      class TwoSamplesIndependent
        include Math
        include Statsample::Test
        include DirtyMemoize
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
        
        def initialize(v1, v2, opts=Hash.new)
          @v1=v1
          @v2=v2
          default={:u=>0, :name=>"Two Sample T Test", :paired_samples=>false, :tails=>:both}
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
        # Presents summary of analysis
        # 
        def summary
          ReportBuilder.new(:no_title=>true).add(self).to_text
        end
        def report_building(b) # :nodoc:
          b.section(:name=>@name) {|g|
            g.table(:name=>"Mean and standard deviation", :header=>["Variable", "m", "sd","n"]) {|t|
              t.row([1,"%0.4f" % @v1.mean,"%0.4f" % @v1.sd,@v1.n_valid])
              t.row([2,"%0.4f" % @v2.mean,"%0.4f" % @v2.sd, @v2.n_valid])
            }
            g.section(:name=>"Levene Test") {|g1|
              g1.parse_element(Statsample::Test.levene([@v1,@v2]))
            }
            
            g.table(:name=>"T statistics",:header=>["Type","t","df", "p (#{tails} tails)"]) {|t|
              t.row(["Equal variance", "%0.4f" % t_equal_variance, df_equal_variance, "%0.4f" % probability_equal_variance])
              t.row(["Non equal variance", "%0.4f" % t_not_equal_variance, "%0.4f" % df_not_equal_variance, "%0.4f" % probability_not_equal_variance])
            }
          }
        end
      end      
    end
  end
end
