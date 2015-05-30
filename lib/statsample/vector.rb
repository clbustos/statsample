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

    # Original data.
    attr_reader :data
    # Valid data. Equal to data, minus values assigned as missing values
    attr_reader :valid_data
    # Missing values array
    attr_reader :missing_data
    # Original data, with all missing values replaced by nils
    attr_reader :data_with_nils

    # Creates a new Vector object.
    # * <tt>data</tt> Any data which can be converted on Array
    # * <tt>type</tt> Level of meausurement. See Vector#type
    # * <tt>opts</tt> Hash of options
    #   * <tt>:missing_values</tt>  Array of missing values. See Vector#missing_values
    #   * <tt>:today_values</tt> Array of 'today' values. See Vector#today_values
    #   * <tt>:labels</tt> Labels for data values
    #   * <tt>:name</tt> Name of vector
    def initialize(data=[], type=:object, opts=Hash.new)
      if type == :ordinal or type == :scale
        $stderr.puts "WARNING: #{type} has been deprecated. Use :numeric instead."
        type = :numeric
      end

      if type == :nominal
        $stderr.puts "WARNING: nominal has been deprecated. Use :object instead."
        type = :object
      end

      @data=data.is_a?(Array) ? data : data.to_a
      @type=type
      opts_default={
        :missing_values=>[],
        :today_values=>['NOW','TODAY', :NOW, :TODAY],
        :labels=>{},
        :name=>nil
      }
      @opts=opts_default.merge(opts)
      if  @opts[:name].nil?
        @@n_table||=0
        @@n_table+=1
        @opts[:name]="Vector #{@@n_table}"
      end
      @missing_values=@opts[:missing_values]
      @labels=@opts[:labels]
      @today_values=@opts[:today_values]
      @name=@opts[:name]
      @valid_data=[]
      @data_with_nils=[]
      @date_data_with_nils=[]
      @missing_data=[]
      @has_missing_data=nil
      @numeric_data=nil
      set_valid_data
      self.type=type
    end
    # Create a vector using (almost) any object
    # * Array: flattened
    # * Range: transformed using to_a
    # * Statsample::Vector
    # * Numeric and string values
    def self.[](*args)
      values=[]
      args.each do |a|
        case a
        when Array
          values.concat a.flatten
        when Statsample::Vector
          values.concat a.to_a
        when Range
          values.concat  a.to_a
        else
          values << a
        end
      end
      vector=new(values)
      vector.type=:numeric if vector.can_be_numeric?
      vector
    end
    # Create a new numeric type vector
    # Parameters
    # [n]      Size
    # [val]    Value of each value
    # [&block] If block provided, is used to set the values of vector
    def self.new_numeric(n,val=nil, &block)
      if block
        vector=n.times.map {|i| block.call(i)}.to_numeric
      else
        vector=n.times.map { val}.to_numeric
      end
      vector.type=:numeric
      vector
    end

    # Deprecated. Use new_numeric instead.
    def self.new_scale(n, val=nil,&block)
      $stderr.puts "WARNING: .new_scale has been deprecated. Use .new_numeric instead."
      new_numeric n, val, &block
    end

    def vector_standarized_compute(m,sd) # :nodoc:
      @data_with_nils.collect{|x| x.nil? ? nil : (x.to_f - m).quo(sd) }.to_vector(:numeric)
    end
    # Return a vector usign the standarized values for data
    # with sd with denominator n-1. With variance=0 or mean nil,
    # returns a vector of equal size full of nils
    #
    def vector_standarized(use_population=false)
      check_type :numeric
      m=mean
      sd=use_population ? sdp : sds
      return ([nil]*size).to_numeric if mean.nil? or sd==0.0
      vector=vector_standarized_compute(m,sd)
      vector.name=_("%s(standarized)")  % @name
      vector
    end
    def vector_centered_compute(m) #:nodoc:
      @data_with_nils.collect {|x| x.nil? ? nil : x.to_f-m }.to_numeric
    end
    # Return a centered vector
    def vector_centered
      check_type :numeric
      m=mean
      return ([nil]*size).to_numeric if mean.nil?
      vector=vector_centered_compute(m)
      vector.name=_("%s(centered)") % @name
      vector
    end

    alias_method :standarized, :vector_standarized
    alias_method  :centered, :vector_centered
    def box_cox_transformation(lambda) # :nodoc:
      raise "Should be a numeric" unless @type==:numeric
      @data_with_nils.collect{|x|
      if !x.nil?
        if(lambda==0)
          Math.log(x)
        else
          (x**lambda-1).quo(lambda)
        end
      else
        nil
      end
      }.to_vector(:numeric)
    end

    # Retrieves label for value x. Retrieves x if
    # no label defined.
    def labeling(x)
      @labels.has_key?(x) ? @labels[x].to_s : x.to_s
    end
    alias_method :n, :size
    alias_method :to_ary, :to_a

    # Returns the database type for the vector, according to its content
    def db_type(dbs='mysql')
    # first, detect any character not number
    if @data.find {|v|  v.to_s=~/\d{2,2}-\d{2,2}-\d{4,4}/} or @data.find {|v|  v.to_s=~/\d{4,4}-\d{2,2}-\d{2,2}/}
      return "DATE"
    elsif @data.find {|v|  v.to_s=~/[^0-9e.-]/ }
      return "VARCHAR (255)"
    elsif @data.find {|v| v.to_s=~/\./}
      return "DOUBLE"
    else
      return "INTEGER"
    end
    end
    # Return true if all data is Date, "today" values or nil
    def can_be_date?
    if @data.find {|v|
    !v.nil? and !v.is_a? Date and !v.is_a? Time and (v.is_a? String and !@today_values.include? v) and (v.is_a? String and !(v=~/\d{4,4}[-\/]\d{1,2}[-\/]\d{1,2}/))}
      false
    else
      true
    end
    end
    # Return true if all data is Numeric or nil
    def can_be_numeric?
      if @data.find {|v| !v.nil? and !v.is_a? Numeric and !@missing_values.include? v}
        false
      else
        true
      end
    end

    def to_s
      sprintf("Vector(type:%s, n:%d)[%s]",@type.to_s,@data.size, @data.collect{|d| d.nil? ? "nil":d}.join(","))
    end
    # Ugly name. Really, create a Vector for standard 'matrix' package.
    # <tt>dir</tt> could be :horizontal or :vertical
    def to_matrix(dir=:horizontal)
      case dir
      when :horizontal
        Matrix[@data]
      when :vertical
        Matrix.columns([@data])
      end
    end
    def inspect
      self.to_s
    end
    # Retrieves uniques values for data.
    def factors
      if @type==:numeric
        @numeric_data.uniq.sort
      elsif @type==:date
        @date_data_with_nils.uniq.sort
      else
        @valid_data.uniq.sort
      end
    end
    if Statsample::STATSAMPLE__.respond_to?(:frequencies)
      # Returns a hash with the distribution of frecuencies for
      # the sample
      def frequencies
        Statsample::STATSAMPLE__.frequencies(@valid_data)
      end
    else
      def frequencies #:nodoc:
        _frequencies
      end
    end


    def _frequencies #:nodoc:
      @valid_data.inject(Hash.new) {|a,x|
        a[x]||=0
        a[x]=a[x]+1
        a
      }
    end
    # Returns a hash with the distribution of proportions of
    # the sample.
    def proportions
        frequencies.inject({}){|a,v|
            a[v[0]] = v[1].quo(n_valid)
            a
        }
    end
    # Proportion of a given value.
    def proportion(v=1)
        frequencies[v].quo(@valid_data.size)
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

      # Variance of p, according to poblation size
      def variance_proportion(n_poblation, v=1)
        Statsample::proportion_variance_sample(self.proportion(v), @valid_data.size, n_poblation)
      end
      # Variance of p, according to poblation size
      def variance_total(n_poblation, v=1)
        Statsample::total_variance_sample(self.proportion(v), @valid_data.size, n_poblation)
      end
      def proportion_confidence_interval_t(n_poblation,margin=0.95,v=1)
        Statsample::proportion_confidence_interval_t(proportion(v), @valid_data.size, n_poblation, margin)
      end
      def proportion_confidence_interval_z(n_poblation,margin=0.95,v=1)
        Statsample::proportion_confidence_interval_z(proportion(v), @valid_data.size, n_poblation, margin)
      end

      self.instance_methods.find_all{|met| met=~/_slow$/}.each do |met|
          met_or=met.gsub("_slow","")
          if !self.method_defined?(met_or)
              alias_method met_or, met
          end
      end

      ######
      ### numeric Methods
      ######

    def set_date_data
      @date_data_with_nils=@data.collect do|x|
        if x.is_a? Date
          x
        elsif x.is_a? Time
          Date.new(x.year, x.month, x.day)
        elsif x.is_a? String and x=~/(\d{4,4})[-\/](\d{1,2})[-\/](\d{1,2})/
          Date.new($1.to_i,$2.to_i,$3.to_i)
        elsif @today_values.include? x
          Date.today()
        elsif @missing_values.include? x or x.nil?
          nil
        end
      end
    end

    def set_numeric_data
      @numeric_data=@valid_data.collect do|x|
        if x.is_a? Numeric
          x
        elsif x.is_a? String and x.to_i==x.to_f
          x.to_i
        else
          x.to_f
        end
      end
    end

    private :set_date_data, :set_numeric_data

    # The range of the data (max - min)
    def range;
      check_type :numeric
      @numeric_data.max - @numeric_data.min
    end
    # The sum of values for the data
    def sum
      check_type :numeric
      @numeric_data.inject(0){|a,x|x+a} ;
    end
    # The arithmetical mean of data
    def mean
      check_type :numeric
      sum.to_f.quo(n_valid)
    end
    # Sum of squares for the data around a value.
    # By default, this value is the  mean
    #   ss= sum{(xi-m)^2}
    #
    def sum_of_squares(m=nil)
      check_type :numeric
      m||=mean
      @numeric_data.inject(0){|a,x| a+(x-m).square}
    end
    # Sum of squared deviation
    def sum_of_squared_deviation
      check_type :numeric
      @numeric_data.inject(0) {|a,x| x.square+a} - (sum.square.quo(n_valid))
    end

    # Population variance (denominator N)
    def variance_population(m=nil)
      check_type :numeric
      m||=mean
      squares=@numeric_data.inject(0){|a,x| x.square+a}
      squares.quo(n_valid) - m.square
    end


    # Population Standard deviation (denominator N)
    def standard_deviation_population(m=nil)
      check_type :numeric
      Math::sqrt( variance_population(m) )
    end

    # Population average deviation (denominator N)
    # author: Al Chou

    def average_deviation_population( m = nil )
      check_type :numeric
      m ||= mean
      ( @numeric_data.inject( 0 ) { |a, x| ( x - m ).abs + a } ).quo( n_valid )
    end
    def median_absolute_deviation
      med=median
      recode {|x| (x-med).abs}.median
    end
    alias  :mad :median_absolute_deviation
    # Sample Variance (denominator n-1)
    def variance_sample(m=nil)
      check_type :numeric
      m||=mean
      sum_of_squares(m).quo(n_valid - 1)
    end

    # Sample Standard deviation (denominator n-1)
    def standard_deviation_sample(m=nil)
        check_type :numeric
        m||=mean
        Math::sqrt(variance_sample(m))
    end
    # Skewness of the sample
    def skew(m=nil)
        check_type :numeric
        m||=mean
        th=@numeric_data.inject(0){|a,x| a+((x-m)**3)}
        th.quo((@numeric_data.size)*sd(m)**3)
    end
    # Kurtosis of the sample
    def kurtosis(m=nil)
        check_type :numeric
        m||=mean
        fo=@numeric_data.inject(0){|a,x| a+((x-m)**4)}
        fo.quo((@numeric_data.size)*sd(m)**4)-3

    end
    # Product of all values on the sample
    #
    def product
        check_type :numeric
        @numeric_data.inject(1){|a,x| a*x }
    end

    # With a fixnum, creates X bins within the range of data
    # With an Array, each value will be a cut point
    def histogram(bins=10)
      check_type :numeric

      if bins.is_a? Array
        #h=Statsample::Histogram.new(self, bins)
        h=Statsample::Histogram.alloc(bins)
      else
        # ugly patch. The upper limit for a bin has the form
        # x < range
        #h=Statsample::Histogram.new(self, bins)
        min,max=Statsample::Util.nice(@valid_data.min,@valid_data.max)
        # fix last data
        if max==@valid_data.max
          max+=1e-10
        end
        h=Statsample::Histogram.alloc(bins,[min,max])
        # Fix last bin

      end
      h.increment(@valid_data)
      h
    end

    # Coefficient of variation
    # Calculed with the sample standard deviation
    def coefficient_of_variation
        check_type :numeric
        standard_deviation_sample.quo(mean)
    end
    # Standard error of the distribution mean
    # Calculated using sd/sqrt(n)
    def standard_error
      standard_deviation_sample.quo(Math.sqrt(valid_data.size))
    end
    alias :se :standard_error

    alias_method :sdp, :standard_deviation_population
    alias_method :sds, :standard_deviation_sample
    alias_method :adp, :average_deviation_population
    alias_method :cov, :coefficient_of_variation
    alias_method :variance, :variance_sample
    alias_method :sd, :standard_deviation_sample
    alias_method :ss, :sum_of_squares
    include_aliasing Statsample::Vector::GSL_ if Statsample.has_gsl?
  end
end
