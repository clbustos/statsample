module Statsample
  module Test
    # From Wikipedia:
    # An F-test is any statistical test in which the test statistic has an F-distribution under the null hypothesis. It is most often used when comparing statistical models that have been fit to a data set, in order to identify the model that best fits the population from which the data were sampled.
    class F
      include GetText
      bindtextdomain("statsample")

      include Statsample::Test

      attr_reader :ss_num, :ss_den, :df_num, :df_den, :ss_total, :df_total
      # Tails for probability (:both, :left or :right)
      attr_accessor :tails
      # Name of F analysis
      attr_accessor :name
      # Name of numerator
      attr_accessor :name_numerator
      # Name of denominator
      attr_accessor :name_denominator

      # Parameters:
      # * ss_num: explained variance / between group variance
      # * ss_den: unexplained variance / within group variance
      # * df_num: degrees of freedom for explained variance / k-1
      # * df_den: degrees of freedom for unexplained variance / n-k
      def initialize(ss_num, ss_den, df_num, df_den, opts=Hash.new)
        @ss_num=ss_num
        @ss_den=ss_den
        @df_num=df_num
        @df_den=df_den
        @ss_total=ss_num+ss_den
        @df_total=df_num+df_den
        opts_default={:tails=>:right, :name_numerator=>"Numerator", :name_denominator=>"Denominator", :name=>"F Test"}
        @opts=opts_default.merge(opts)
        raise "Tails should be right or left, not both" if @opts[:tails]==:both
        opts_default.keys.each {|k|
          send("#{k}=", @opts[k])
        }
      end
      def summary
        ReportBuilder.new(:no_title=>true).add(self).to_text
      end
      def f
        (@ss_num.quo(@df_num)).quo(@ss_den.quo(@df_den))
      end
      # probability
      def probability
        p_using_cdf(Distribution::F.cdf(f, @df_num, @df_den), tails)
      end
      def report_building(builder)#:nodoc:
        builder.section(:name=>@name) do |b|
          b.table(:name=>_("%s Table") % @name, :header=>%w{source ss df f p}.map {|v| _(v)}) do |t|
            t.row([@name_numerator, sprintf("%0.3f",@ss_num),  @df_num,  sprintf("%0.3f",f), sprintf("%0.3f", probability)])
            t.row([@name_denominator, sprintf("%0.3f",@ss_den), @df_den, "", ""])
            t.row([_("Total"), sprintf("%0.3f",@ss_total), @df_total,"",""])
          end
        end
      end
    end
  end
end
