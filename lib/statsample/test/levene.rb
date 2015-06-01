module Statsample
  module Test
    # = Levene Test for Equality of Variances
    # From NIST/SEMATECH:
    # <blockquote>Levene's test ( Levene, 1960) is used to test if k samples have equal variances. Equal variances across samples is called homogeneity of variance. Some statistical tests, for example the analysis of variance, assume that variances are equal across groups or samples. The Levene test can be used to verify that assumption.</blockquote>
    # Use:
    #   require 'statsample'
    #   a = Daru::Vector.new([1,2,3,4,5,6,7,8,100,10])
    #   b = Daru::Vector.new([30,40,50,60,70,80,90,100,110,120])
    # 
    #   levene=Statsample::Test::Levene.new([a,b])
    #   puts levene.summary
    #   
    # Output:
    #   Levene Test
    #   F: 0.778121319848449
    #   p: 0.389344552595791
    #
    # Reference:
    # * NIST/SEMATECH e-Handbook of Statistical Methods. Available on http://www.itl.nist.gov/div898/handbook/eda/section3/eda35a.htm
    class Levene
      include Statsample::Test
      include Summarizable
      # Degrees of freedom 1 (k-1)
      attr_reader :d1
      # Degrees of freedom 2 (n-k)
      attr_reader :d2
      # Name of test
      attr_accessor :name
      # Input could be an array of vectors or a dataset
      def initialize(input, opts=Hash.new())
        if input.is_a? Daru::DataFrame
          @vectors = input.to_hash.values
        else
          @vectors = input
        end
        @name=_("Levene Test")
        opts.each{|k,v|
          self.send("#{k}=",v) if self.respond_to? k
        }
        compute
      end
      # Value of the test
      def f
        @w
      end
      def report_building(builder) # :nodoc:
        builder.text "%s : F(%d, %d) = %0.4f , p = %0.4f" % [@name, @d1, @d2, f, probability]
      end
      def compute
        n=@vectors.inject(0) { |ac,v| ac + v.n_valid}
        
        zi=@vectors.collect do |vector|
          mean=vector.mean
          Daru::Vector.new(vector.collect { |v| (v - mean).abs })
        end
        
        total_mean = Daru::Vector.new(
          zi.inject([]) do |ac,vector|
            ac + vector.only_valid(:array)
          end
        ).mean
      
        k = @vectors.size
        sum_num = zi.inject(0) do |ac,vector|
          ac + (vector.size * (vector.mean - total_mean)**2)
        end
        
        sum_den = zi.inject(0) do |ac,vector|
          z_mean = vector.mean
          ac + vector.only_valid(:array).inject(0) do |acp,zij|
            acp + (zij - z_mean)**2
          end
        end

        @w  = ((n - k) * sum_num).quo((k - 1) * sum_den)
        @d1 = k - 1
        @d2 = n - k
      end
      private :compute
      # Probability.
      # With H_0 = Sum(s2)=0, probability of getting a value of the test upper or equal to the obtained on the sample
      def probability
        p_using_cdf(Distribution::F.cdf(f, @d1, @d2), :right)
      end
    end
  end
end
