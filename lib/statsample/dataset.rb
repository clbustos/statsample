require 'statsample/vector'

class Hash
  # Creates a Statsample::Dataset based on a Hash
  def to_dataframe(*args)
    Statsample::Dataset.new(self, *args)
  end

  alias :to_dataset :to_dataframe
end

class Array
  def prefix(s) # :nodoc:
    self.collect{|c| s+c.to_s }
  end
  def suffix(s) # :nodoc:
    self.collect{|c| c.to_s+s }
  end
end

module Statsample
  # == Deprecation Warning
  # 
  # This class will soon be replaced by Daru::DataFrame in the 
  # next release. Please see the daru docs at https://github.com/v0dro/daru 
  # for more details
  class Dataset < Daru::DataFrame
    # Ordered ids of vectors
    def fields
      $stderr.puts "WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using Daru::DataFrame#vectors.\n"
      @vectors.to_a
    end

    def name= new_name
      $stderr.puts "WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using Daru::DataFrame#rename.\n"

      rename new_name
    end
    # Number of cases
    def cases
      $stderr.puts "WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using Daru::DataFrame#nrows.\n"

      nrows
    end

    # == Deprecation Warning
    # 
    # This class will soon be replaced by Daru::DataFrame in the 
    # next release. Use Daru::DataFrame.crosstab_by_assignation 
    # for the same effect. Please see the daru docs at 
    # https://github.com/v0dro/daru for more details.
    def self.crosstab_by_assignation(rows,columns,values)
      ds = super(rows, columns, values)
      Dataset.new ds.to_hash
    end

    # == Deprecation Warning
    # 
    # This class will soon be replaced by Daru::DataFrame in the 
    # next release. Use Daru::DataFrame.new for the same effect. 
    # Please see the daru docs at https://github.com/v0dro/daru for more details.
    def initialize(vectors={}, fields=[])
      $stderr.puts "WARNING: Statsample::Dataset and Statsample::Vector have been deprecated in favor of Daru::DataFrame and Daru::Vector. Please switch to using that.\n"

      if vectors.instance_of? Array
        @fields=vectors.dup
        super({}, order: @fields.map { |e| e.respond_to?(:to_sym) ? e.to_sym : e })
      else
        # Check vectors
        @vectors = {}
        vectors.each do |k,v|
          @vectors[k.respond_to?(:to_sym) ? k.to_sym : k] = v
        end
        @fields  = fields
        super @vectors, order: @fields.map { |e| e.respond_to?(:to_sym) ? e.to_sym : e }
      end
    end

    def from_to(from,to)
      raise NoMethodError, "This method is no longer supported. To see the vector index use Daru::DataFrame#vectors"
    end

    def add_vector(name, vector)
      raise NoMethodError, "Deprecated. Use Daru::DataFrame#[]= directly."
    end

    def add_case_array(v)
      raise NoMethodError, "Deprecated. Use Daru::DataFrame#add_row instead."
    end

    def add_case(v,uvd=true)
      raise NoMethodError, "Deprecated. Use Daru::DataFrame#add_row instead."
    end

    def update_valid_data
      raise NoMethodError, "Deprecated. Use Daru::DataFrame#update instead. Also see Daru.lazy_update in the daru docs."
    end

    def each_array
      raise NoMethodError, "Deprecated. Use Daru::DataFrame#each_row instead."
    end

    def fields=(f)
      $stderr.puts "WARNING: Deprecated. Use Daru::DataFrame#reindex_vectors! instead.\n"

      reindex_vectors! f
    end

    # Returns the vector named i
    def [](i)
      $stderr.puts "WARNING: Daru uses symbols instead of strings for naming vectors. Please switch to symbols.\n"

      if i.is_a? Range
        beg = i.begin.respond_to?(:to_sym) ? i.to_sym : i
        en = i.end.respond_to?(:to_sym) ? i.to_sym : i
        super(beg..en)
      else
        super i.to_sym
      end
    end

    def []=(i,v)
      $stderr.puts "WARNING: Daru uses symbols instead of strings for naming vectors. Please switch to symbols.\n"

      super i, v
    end

    if Statsample.has_gsl?
      def clear_gsl
        raise NoMethodError, "This method is no longer needed/supported."
      end
    end   
  end
end
