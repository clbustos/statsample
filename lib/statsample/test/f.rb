module Statsample
  module Test
    # From Wikipedia:
    # An F-test is any statistical test in which the test statistic has an F-distribution under the null hypothesis. It is most often used when comparing statistical models that have been fit to a data set, in order to identify the model that best fits the population from which the data were sampled.
    class F
      include Statsample::Test
      include Summarizable
      attr_reader :var_num, :var_den, :df_num, :df_den, :var_total, :df_total
      # Tails for probability (:both, :left or :right)
      attr_accessor :tails
      # Name of F analysis
      attr_accessor :name

      # Parameters:
      # * var_num: variance numerator
      # * var_den: variance denominator
      # * df_num: degrees of freedom numerator
      # * df_den: degrees of freedom denominator
      def initialize(var_num, var_den, df_num, df_den, opts=Hash.new)
        @var_num=var_num
        @var_den=var_den
        @df_num=df_num
        @df_den=df_den
        @var_total=var_num+var_den
        @df_total=df_num+df_den
        opts_default={:tails=>:right, :name=>_("F Test")}
        @opts=opts_default.merge(opts)
        raise "Tails should be right or left, not both" if @opts[:tails]==:both
        opts_default.keys.each {|k|
          send("#{k}=", @opts[k])
        }
      end
      def f
        @var_num.quo(@var_den)
      end
      def to_f
        f
      end
      # probability
      def probability
        p_using_cdf(Distribution::F.cdf(f, @df_num, @df_den), tails)
      end
      def report_building(builder) #:nodoc:
        if @df_num.is_a? Integer and @df_den.is_a? Integer
          builder.text "%s : F(%d, %d) = %0.4f , p = %0.4f" % [@name, @df_num, @df_den, f, probability]
        else
          builder.text "%s : F(%0.2f, %0.2f) = %0.4f , p = %0.4f" % [@name, @df_num, @df_den, f, probability]
        end
      end
    end
  end
end
