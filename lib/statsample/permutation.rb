module Statsample
  # Permutation class systematically generates all permutations 
  # of elements on an array, using Dijkstra algorithm (1997).
  #
  # As argument, you could use 
  # * Number of elements: an array with numbers from 0 to n-1 will be used
  # * Array: if ordered, you obtain permutations on lexicographic order
  #          you can repeat elements, if you will.
  #  
  #  Use:
  #  perm=Statsample::Permutation.new(3)
  #  perm.permutations
  #  => [[0,1,2],[0,2,1],[1,0,2],[1,2,0],[2,0,1],[2,1,0]]
  #  perm=Statsample::Permutation.new([0,0,1,1])
  #  => [[0,0,1,1],[0,1,0,1],[0,1,1,0],[1,0,0,1],[1,0,1,0],[1,1,0,0]]
  #
  # == Reference:
  # * http://www.cut-the-knot.org/do_you_know/AllPerm.shtml
  class Permutation
    attr_reader :permutation_number
    def initialize(v)
      if v.is_a? Numeric
        @original=(0...v.to_i).to_a
        @permutation_number=factorial(v)
      else
        @original=v
        calculate_max_iterations_from_array
      end
      @n=@original.size
      reset
    end
    def calculate_max_iterations_from_array
      if @original.respond_to? :frequencies
        freq=@original.frequencies
      else
        freq=@original.to_vector.frequencies
      end
      if freq.length==@original.size
        @permutation_number=factorial(@original.size)
      else
        numerator=factorial(@original.size)
        denominator=freq.inject(1) {|a,v|
          a*factorial(v[1])
        }
        @permutation_number=numerator/denominator
      end
    end
    def factorial (n)
      (1..n).inject(1){|a,v| a*v}
    end
    def reset
      @iterations=0
      @data=@original.dup
    end
    def each
      reset
      @permutation_number.times do
        yield next_value
      end
    end
    def permutations
      a=Array.new
      each {|c| a.push(c)}
      a
    end
    def next_value
      prev=@data.dup
      i = @n-1
      while @data[i-1] >= @data[i]
        #return false if i<0 
        i=i-1
      end
      j=@n
      while @data[j-1] <= @data[i-1]
        j=j-1
      end
      # swap values at positions (i-1) and (j-1)
      swap(i-1, j-1);    
      
      i+=1
      j = @n
      
      while (i < j)
        swap(i-1, j-1);
        i+=1;
        j-=1;
        sprintf("%d %d",i,j)
      end
      prev
    end
    def swap(i,j)
      tmp=@data[i]
      @data[i]=@data[j]
      @data[j]=tmp
    end
  end
end
