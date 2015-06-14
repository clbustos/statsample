module Statsample
  module Test
    # == Kolmogorov-Smirnov's test of equality of distributions.
    class KolmogorovSmirnov
      
      attr_reader :d
      include Statsample::Test
      include Summarizable
      # Creates a new Kolmogorov-Smirnov test
      # d1 should have each method
      # d2 could be a Distribution class, with a cdf method,
      # a vector or a lambda
      def initialize(d1,d2)
        raise "First argument should have each method" unless d1.respond_to? :each
        @d1=make_cdf(d1)
        if d2.respond_to? :cdf or d2.is_a? Proc
          @d2=d2
        elsif d2.respond_to? :each
          @d2=make_cdf(d2)
        else
           raise "Second argument should respond to cdf or each"    
         end
         calculate
      end
      
      def calculate
         d=0
        @d1.each {|x|
        v1=@d1.cdf(x);
        v2=@d2.is_a?(Proc) ? @d2.call(x) : @d2.cdf(x)
        d=(v1-v2).to_f.abs if (v1-v2).abs>d
        }
        @d=d
      end

      # Make a wrapper EmpiricDistribution to any method which implements
      # each on Statsample::Vector, only uses non-missing data.
      def make_cdf(v)
        v.is_a?(Daru::Vector) ? EmpiricDistribution.new(v.only_valid.to_a) : EmpiricDistribution.new(v)
      end

      class EmpiricDistribution
        def initialize(data)
          @min=data.min
          @max=data.max
          @data=data.sort
          @n=data.size
        end
        def each
          @data.each {|x|
            yield x
          }
        end
        def cdf(x)
          return 0 if x<@min
          return 1 if x>=@max
          v=@data.index{|v1| v1>=x}
          v.nil? ? 0 : (v+(x==@data[v]? 1 : 0)).quo(@n)
        end
      end # End EmpiricDistribution
    end
  end
end
