module Statsample
  module Bivariate
    # = Pearson correlation coefficient (r) 
    # 
    # The moment-product Pearson's correlation coefficient, known as 'r'
    # is a measure of bivariate associate between two continous
    # variables.
    # 
    # == Usage
    #   a = Daru::Vector.new([1,2,3,4,5,6])
    #   b = Daru::Vector.new([2,3,4,5,6,7])
    #   pearson = Statsample::Bivariate::Pearson.new(a,b)
    #   puts pearson.r
    #   puts pearson.t
    #   puts pearson.probability
    #   puts pearson.summary
    # 
    class Pearson
      
      include Statsample::Test
      include Summarizable
      # Name of correlation
      attr_accessor :name
      # Tails for probability (:both, :left or :right)
      attr_accessor :tails     
      attr_accessor :n      
      def initialize(v1,v2,opts=Hash.new)
        @v1_name,@v2_name = v1.name,v2.name
        @v1,@v2           = Statsample.only_valid_clone(v1,v2)
        @n=@v1.size
        opts_default={
          :name=>_("Correlation (%s - %s)") % [@v1_name, @v2_name],
          :tails=>:both
        }
        @opts=opts.merge(opts_default)
        @opts.each{|k,v|
          self.send("#{k}=",v) if self.respond_to? k
        }
      end
      def r
        Statsample::Bivariate.pearson(@v1,@v2)
      end
      def t
        Statsample::Bivariate.t_pearson(@v1,@v2)
      end
      def probability
        p_using_cdf(Distribution::T.cdf(t, @v1.size-2), tails)
      end
      def report_building(builder)
        builder.text(_("%s : r=%0.3f (t:%0.3f, g.l.=%d, p:%0.3f / %s tails)") % [@name, r,t, (n-2), probability, tails])
      end
    end
  end
end