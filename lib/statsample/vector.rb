require 'date'
require 'statsample/vector/gsl'

module Statsample::VectorShorthands
  # Creates a new Statsample::Vector object
  # Argument should be equal to Vector.new
  def to_vector(*args)
    Daru::Vector.new(self)
  end

  # Creates a new Daru::Vector object of type :scale.
  # Deprecated. Use to_numeric instead.
  def to_scale(*args)
    $stderr.puts "WARNING: to_scale has been deprecated. Use to_numeric instead."
    Daru::Vector.new(self, *args)
  end

  def to_numeric(*args)
    Daru::Vector.new(self)
  end
end

class Array
  include Statsample::VectorShorthands
end

if Statsample.has_gsl?
  module GSL
    class Vector
      include Statsample::VectorShorthands
    end
  end
end
module Statsample


  # Collection of values on one dimension. Works as a column on a Spreadsheet.
  #
  # == Usage
  # The fast way to create a vector uses Array.to_vector or Array.to_numeric.
  #
  # == Deprecation Warning
  # 
  # Statsample::Vector has been deprecated in favour of Daru::Vector. Daru is
  # a dedicated data analysis and manipulation library that brings awesome
  # data analysis functionality to ruby. Check out the daru docs at <link>
  class Vector < Daru::Vector
    include Statsample::VectorShorthands

    # Valid data. Equal to data, minus values assigned as missing values.
    # 
    # == Deprecation Warning
    # 
    # Use Daru::Vector#only_valid instead of this method.
    def valid_data
      only_valid.to_a
    end
    # Missing values array
    # 
    # == Deprecation Warning
    # 
    # Use Daru::Vector#only_valid instead of this method.
    def missing_data
      only_missing.to_a
    end
    # Original data, with all missing values replaced by nils
    # 
    # == Deprecation Warning
    # 
    # Use Daru::Vector#to_a instead of this method.
    def data_with_nils
      to_a
    end

    def type= val
      raise NoMethodError, "Daru::Vector automatically figures the type of data. There is no need to assign it anymore."
    end

    def initialize(data=[], type=:object, opts=Hash.new)
      if type == :ordinal or type == :scale
        $stderr.puts "WARNING: #{type} has been deprecated."
      end

      if type == :nominal
        $stderr.puts "WARNING: nominal has been deprecated."
      end

      if opts[:today_values]
        raise ArgumentError, "This option is no longer supported in Vector. Watch out for the next version of Daru::Vector that will have full time series support"
      end

      if  opts[:name].nil?
        @@n_table||=0
        @@n_table+=1
        opts[:name] = "Vector #{@@n_table}"
      end

      super(data, opts)
    end

    # Create a vector using (almost) any object
    # * Array: flattened
    # * Range: transformed using to_a
    # * Statsample::Vector
    # * Numeric and string values
    # 
    # == Deprecation Warning
    # 
    # Statsample::Vector is to be replaced by Daru::Vector soon. Use the 
    # equivalent method Daru::Vector.[] for this purpose.
    def self.[](*args)
      super *args
    end
    # Create a new numeric type vector
    # Parameters
    # [n]      Size
    # [val]    Value of each value
    # [&block] If block provided, is used to set the values of vector
    # 
    # == Deprecation Warning
    # 
    # Statsample::Vector is to be replaced by Daru::Vector soon. Use the 
    # equivalent method Daru::Vector.[] for this purpose.
    def self.new_numeric(n,val=nil, &block)
      if block
        Statsample::Vector.new(n.times.map {|i| block.call(i)})
      else
        Statsample::Vector.new(n.times.map { val })
      end
    end

    # Deprecated. Use new_numeric instead.
    def self.new_scale(n, val=nil,&block)
      $stderr.puts "WARNING: .new_scale has been deprecated. Use .new_numeric instead."
      new_numeric n, val, &block
    end

    alias_method :n, :size
    alias_method :to_ary, :to_a

    # Return true if all data is Date, "today" values or nil
    def can_be_date?
      raise NoMethodError, "This method is no longer supported."
    end
    # Return true if all data is Numeric or nil
    def can_be_numeric?
      type == :numeric
    end

    def to_s
      sprintf("Vector(type:%s, n:%d)[%s]",@type.to_s,@data.size, @data.collect{|d| d.nil? ? "nil":d}.join(","))
    end

    def report_building(b)
      b.section(:name=>name) do |s|
        s.text _("n :%d") % n
        s.text _("n valid:%d") % n_valid
        if @type==:object
          s.text  _("factors:%s") % factors.join(",")
          s.text   _("mode: %s") % mode

          s.table(:name=>_("Distribution")) do |t|
            frequencies.sort.each do |k,v|
              key=labels.has_key?(k) ? labels[k]:k
              t.row [key, v , ("%0.2f%%" % (v.quo(n_valid)*100))]
            end
          end
        end

        s.text _("median: %s") % median.to_s if(@type==:numeric or @type==:numeric)
        if(@type==:numeric)
          s.text _("mean: %0.4f") % mean
          if sd
            s.text _("std.dev.: %0.4f") % sd
            s.text _("std.err.: %0.4f") % se
            s.text _("skew: %0.4f") % skew
            s.text _("kurtosis: %0.4f") % kurtosis
          end
        end
      end
    end
  end
end
