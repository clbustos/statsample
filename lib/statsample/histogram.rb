module Statsample
  # A histogram consists of a set of bins which count the 
  # number of events falling into a given range of a continuous variable x. 
  # 
  # This implementations follows convention of GSL
  # for specification.
  # 
  #  * Verbatim: *
  #
  #  The range for bin[i] is given by range[i] to range[i+1]. 
  #  For n bins there are n+1 entries in the array range. 
  #  Each bin is inclusive at the lower end and exclusive at the upper end. 
  #  Mathematically this means that the bins are defined 
  #  by the following inequality,
  # 
  #   bin[i] corresponds to range[i] <= x < range[i+1]
  # 
  #  Here is a diagram of the correspondence between ranges and bins
  #  on the number-line for x,
  # 
  # 
  #      [ bin[0] )[ bin[1] )[ bin[2] )[ bin[3] )[ bin[4] )
  #   ---|---------|---------|---------|---------|---------|---  x
  #    r[0]      r[1]      r[2]      r[3]      r[4]      r[5]
  # 
  # 
  #  In this picture the values of the range array are denoted by r. 
  #  On the left-hand side of each bin the square bracket ‘[’ denotes 
  #  an inclusive lower bound ( r <= x), and the round parentheses ‘)’ 
  #  on the right-hand side denote an exclusive upper bound (x < r). 
  #  Thus any samples which fall on the upper end of the histogram are 
  #  excluded. 
  #  If you want to include this value for the last bin you will need to 
  #  add an extra bin to your histogram. 
  #
  #
  # Reference:
  # http://www.gnu.org/software/gsl/manual/html_node/The-histogram-struct.html
  
    class Histogram
      class << self
        def alloc(n_bins, range=nil, opts=Hash.new)
          Histogram.new(n_bins, range)
          
        end
      end
      attr_accessor :name
      attr_reader :bin
      attr_reader :range
      include GetText
      bindtextdomain("statsample")
      def initialize(p1, min_max=false, opts=Hash.new)
        
        if p1.is_a? Array
          range=p1
          n_bins=p1.size-1
        elsif p1.is_a? Integer
          n_bins=p1
        end
        
        @bin=[0.0]*(n_bins)
        if(min_max)
          min, max=min_max[0], min_max[1]
          range=Array.new(n_bins+1)
          (n_bins+1).times {|i| range[i]=min+(i*(max-min).quo(n_bins)) }
        end
        range||=[0.0]*(n_bins+1)
        set_ranges(range)
        @name=""
        opts.each{|k,v|
        self.send("#{k}=",v) if self.respond_to? k
        }
      end
      
      def increment(x, w=1)
        if x.is_a? Array
          x.each{|y| increment(y,w) }
        elsif x.is_a? Numeric
          (range.size-1).times do |i|
            if x>=range[i] and x<range[i+1]
              @bin[i]+=w
              break
            end
          end
        end
      end
      def set_ranges(range)
        raise "Range size should be bin+1" if range.size!=@bin.size+1
        @range=range
      end
      def to_reportbuilder_text(generator)
        anchor=generator.add_toc_entry(_("Histogram %s") % [@name])
        range.each_with_index do |r,i|
          next if i==@bin.size
          generator.add_text(sprintf("%4.2f : %d", r, @bin[i]))
        end
      end
    end
end
