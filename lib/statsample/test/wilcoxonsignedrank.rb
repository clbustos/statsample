module Statsample
  module Test
    # From Wikipedia:
    # The Wilcoxon signed-rank test is a non-parametric statistical hypothesis test used when comparing two related samples, matched samples, or repeated measurements on a single sample to assess whether their population mean ranks differ (i.e. it is a paired difference test). It can be used as an alternative to the paired Student's t-test, t-test for matched pairs, or the t-test for dependent samples when the population cannot be assumed to be normally distributed.
    class WilcoxonSignedRank
      include Statsample::Test
      include Summarizable
      
      # Name of F analysis
      attr_accessor :name
	    attr_reader :w
	    attr_reader :nr
      attr_writer :tails
      # Parameters:
      def initialize(v1,v2, opts=Hash.new)
		    @v1 = v1
		    @v2 = v2
        opts_default={:name=>_("Wilcoxon Signed Rank Test"),:tails=>:both}
        @opts=opts_default.merge(opts)
        opts_default.keys.each {|k|
          send("#{k}=", @opts[k])
        }
        calculate
      end

      def calculate
		    df = Daru::DataFrame.new({:v1 => @v1,:v2 => @v2})
		    # df[:abs]=df.collect(:row) { |row|  (row[:v2] - row[:v1]).abs }
        df[:abs] = (df[:v2] - df[:v1]).abs
		    df[:sgn] = df.collect(:row) { |row| 
			   r = row[:v2] - row[:v1]
			   r == 0 ? 0 : r/r.abs
		    }
		    df = df.filter_rows { |row| row[:sgn] != 0}
		    df[:rank] = df[:abs].ranked
		    @nr = df.nrows

		    @w = df.collect(:row) { |row|
          row[:sgn] * row[:rank]
		    }.sum
      end

      def report_building(generator) # :nodoc:
        generator.section(:name=>@name) do |s|
          s.table(:name=>_("%s results") % @name) do |t|
            t.row([_("W Value"), "%0.3f" % @w])
            t.row([_("Z"), "%0.3f (p: %0.3f)" % [z, probability_z]])
            if(nr<=10) 
				      t.row([_("Exact probability"), "p-exact: %0.3f" % [probability_exact]])
            end
          end
        end
      end
      def z
		    sigma=Math.sqrt((nr*(nr+1)*(2*nr+1))/6)
		    (w-0.5)/sigma
      end
      # Assuming normal distribution of W, this calculate
      # the probability of samples with Z equal or higher than
      # obtained on sample
      def probability_z
		    (1-Distribution::Normal.cdf(z))*(@tails==:both ? 2:1)
      end
      # Calculate exact probability.
      # Don't calculate for large Nr, please!
      def probability_exact
		    str_format="%0#{nr}b"
		    combinations=2**nr
		    #p str_format
		    total_w=combinations.times.map do |i|
          comb=sprintf(str_format,i)
          w_local=comb.length.times.inject(0) do |ac,j|
            sgn=comb[j]=="0" ? -1 : 1
				    ac+(j+1)*sgn
          end
		    end.sort

  		  total_w.find_all do |v| 
          if @tails==:both
            v<=-w.abs or v>=w.abs
          elsif @tails==:left
            v<=w
          elsif @tails==:right
  				  v>=w
          end
  		  end.count/(combinations.to_f)
      end
    end
  end
end
