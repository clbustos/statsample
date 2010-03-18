module Statsample
  # Combination class systematically generates all combinations of n elements, taken r at a time.
  # With rbgsl, GSL::Combination is available for extra speed
  # == Use:
  #  comb=Statsample::Combination.new(3,5)
  #  => #<Statsample::Combination:0x7f6323804e08 @n=5, @d=#<Statsample::Combination::CombinationGsl:0x7f63237ff7f0 @n=5, @k=3, @c=GSL::Combination>, @k=3>
  #  comb.each{|c| p c }
  #  [0, 1, 2]
  #  [0, 1, 3]
  #  [0, 1, 4]
  #  [0, 2, 3]
  #  [0, 2, 4]
  #  [0, 3, 4]
  #  [1, 2, 3]
  #  [1, 2, 4]
  #  [1, 3, 4]
  #  [2, 3, 4]
  # == Reference:
  # * http://snippets.dzone.com/posts/show/4666
  #
  class Combination
    attr_reader :d
    def initialize(k,n,only_ruby=false)
      @k=k
      @n=n
      if Statsample.has_gsl? and !only_ruby
        @d=CombinationGsl.new(@k,@n)
      else
        @d=CombinationRuby.new(@k,@n)
      end
    end
    def each
      reset
      while a=next_value
        yield a
      end
    end
    def reset
        @d.reset
    end
    def next_value
        @d.next_value
    end
    class CombinationRuby # :nodoc:
      attr_reader :data
      def initialize(k,n)
        raise "k<=n" if k>n
        @k=k
        @n=n
        reset
      end
      def reset
        @data=[]
        (0...@k).each {|i| @data[i] = i }
      end
      def each
        reset
        while a=next_value
            yield a
        end
      end
      def next_value
        return false if !@data
        old_comb=@data.dup
        i = @k - 1;
        @data[i]+=1
        while ((i >= 0) and (@data[i] >= @n - @k + 1 + i)) do
          i-=1;
          @data[i]+=1;
        end
        
        if (@data[0] > @n - @k) # Combination (n-k, n-k+1, ..., n) reached */
          @data=false # No more combinations can be generated 
        else
          # comb now looks like (..., x, n, n, n, ..., n).
          # Turn it into (..., x, x + 1, x + 2, ...) 
          i = i+1
          (i...@k).each{ |i1|
              @data[i1] = @data[i1 - 1] + 1
          }
        end
        return old_comb
      end
    end
    
    # rb-gsl engine for Combinations
    class CombinationGsl # :nodoc:
      def initialize(k,n)
        require 'gsl'
        raise "k<=n" if k>n
        @k=k
        @n=n
        reset
      end
      def reset
        @c= ::GSL::Combination.calloc(@n, @k);
      end
      def next_value
        return false if !@c
        data=@c.data.to_a
        if @c.next != GSL::SUCCESS
          @c=false
        end
        return data
      end
      def each
        reset
        begin
        yield @c.data.to_a
        end while @c.next == GSL::SUCCESS
      end
    end
  end
end
