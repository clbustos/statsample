require 'date'
class Array
    # Creates a new Statsample::Vector object
    # Argument should be equal to Vector.new
	def to_vector(*args)
		Statsample::Vector.new(self,*args)
	end
    # Creates a new Statsample::Vector object of type :scale
    def to_scale(*args)
        Statsample::Vector.new(self, :scale,*args)
    end
end

module Statsample
 
  # Collection of values on one dimension. Works as a column on a Spreadsheet.
  # 
  # == Usage
  # The fast way to create a vector uses Array.to_vector or Array.to_scale.
  #
  #  v=[1,2,3,4].to_vector(:scale)
  #  v=[1,2,3,4].to_scale
  # 
  class Vector
    include Enumerable
    include Writable
    include Summarizable
    # Level of measurement. Could be :nominal, :ordinal or :scale
    attr_reader :type
    # Original data. 
    attr_reader :data
    # Valid data. Equal to data, minus values assigned as missing values
    attr_reader :valid_data
    # Array of values considered as missing. Nil is a missing value, by default
    attr_reader :missing_values 
    # Array of values considered as "Today", with date type. "NOW", "TODAY", :NOW and :TODAY are 'today' values, by default
    attr_reader :today_values
    # Missing values array
    attr_reader :missing_data
    # Original data, with all missing values replaced by nils
    attr_reader :data_with_nils
    # Date date, with all missing values replaced by nils
    attr_reader :date_data_with_nils
    # GSL Object, only available with rbgsl extension and type==:scale
    attr_reader :gsl
    # Change label for specific values
    attr_accessor :labels
    # Name of vector. Should be used for output by many classes
    attr_accessor :name
    
    #
    # Creates a new Vector object.
    # * <tt>data</tt> Array of data.
    # * <tt>type</tt> Level of meausurement. See Vector#type
    # * <tt>opts</tt> Hash of options
    #   * <tt>:missing_values</tt>  Array of missing values. See Vector#missing_values
    #   * <tt>:today_values</tt> Array of 'today' values. See Vector#today_values
    #   * <tt>:labels</tt> Labels for data values
    #   * <tt>:name</tt> Name of vector
    #
    def initialize(data=[], type=:nominal, opts=Hash.new)
      raise "Data should be an array" unless data.is_a? Array
      @data=data
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
      @scale_data=nil
      set_valid_data_intern
      self.type=type
    end
    def self.[](*v)
      vector=new(v)
      vector.type=:scale if vector.can_be_scale?
      vector
    end
    def self.new_scale(n,val=nil, &block)
      if block
        vector=n.times.map {|i| block.call(i)}.to_scale
      else
        vector=n.times.map { val}.to_scale
      end
      
      vector.type=:scale
      vector
    end
    # Creates a duplicate of the Vector.
    # Note: data, missing_values and labels are duplicated, so
    # changes on original vector doesn't propages to copies.
    def dup
      Vector.new(@data.dup,@type, :missing_values => @missing_values.dup, :labels => @labels.dup, :name=>@name)
    end
    # Returns an empty duplicate of the vector. Maintains the type,
    # missing values and labels.
    def dup_empty
      Vector.new([],@type, :missing_values => @missing_values.dup, :labels => @labels.dup, :name=> @name)
    end
    # Raises an exception if type of vector is inferior to t type
    def check_type(t)
      raise NoMethodError if (t==:scale and @type!=:scale) or (t==:ordinal and @type==:nominal) or (t==:date)
    end
    private :check_type

    # Return a vector usign the standarized values for data
    # with sd with denominator n-1. With variance=0 or mean nil,
    # returns a vector of equal size full of nils
    # 
    
    def vector_standarized(use_population=false)
      check_type :scale
      return ([nil]*size).to_scale if mean.nil?
      m=mean
      sd=use_population ? sdp : sds
      return ([nil]*size).to_scale if sd==0.0
      vector=@data_with_nils.collect{|x|
        if !x.nil?
          (x.to_f - m).quo(sd)
        else
          nil
        end
      }.to_vector(:scale)
      vector.name=_("%s(standarized)")  % @name
      vector
    end
    # Return a centered vector
    def vector_centered
      check_type :scale
      m=mean
      vector=@data_with_nils.collect {|x|
        x.nil? ? nil : x.to_f-m
      }.to_scale
      vector.name=_("%s(centered)") % @name
      vector
    end
    
    alias_method :standarized, :vector_standarized
    alias_method  :centered, :vector_centered
    # Return a vector with values replaced with the percentiles
    # of each values
    def vector_percentil
      check_type :ordinal
      c=@valid_data.size
      vector=ranked.map {|i| i.nil? ? nil : (i.quo(c)*100).to_f }.to_vector(@type)
      vector.name=_("%s(percentil)")  % @name
      vector
    end
    def box_cox_transformation(lambda) # :nodoc:
    raise "Should be a scale" unless @type==:scale
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
    }.to_vector(:scale)
    end
    
    # Vector equality.
    # Two vector will be the same if their data, missing values, type, labels are equals
    def ==(v2)
      raise TypeError,"Argument should be a Vector" unless v2.instance_of? Statsample::Vector
      @data==v2.data and @missing_values==v2.missing_values and @type==v2.type and @labels==v2.labels
    end
    
    def _dump(i) # :nodoc:
      Marshal.dump({'data'=>@data,'missing_values'=>@missing_values, 'labels'=>@labels, 'type'=>@type,'name'=>@name})
    end
    
    def self._load(data) # :nodoc:
    h=Marshal.load(data)
    Vector.new(h['data'], h['type'], :missing_values=> h['missing_values'], :labels=>h['labels'], :name=>h['name'])
    end
    # Returns a new vector, with data modified by block.
    # Equivalent to create a Vector after #collect on data 
    def recode(type=nil)
      type||=@type
      @data.collect{|x|
        yield x
      }.to_vector(type)
    end
    # Modifies current vector, with data modified by block.
    # Equivalent to #collect! on @data 
    def recode!
    @data.collect!{|x|
      yield x
    }
    set_valid_data
    end
    # Dicotomize the vector with 0 and 1, based on lowest value
    # If parameter if defined, this value and lower
    # will be 0 and higher, 1
    def dichotomize(low=nil)
      fs=factors
      low||=factors.min
      @data_with_nils.collect{|x|
        if x.nil?
          nil
        elsif x>low
          1
        else
          0
        end
      }.to_scale
    end
    # Iterate on each item.
    # Equivalent to
    #   @data.each{|x| yield x}
    def each
      @data.each{|x| yield(x) }
    end
    
    # Iterate on each item, retrieving index
    def each_index
    (0...@data.size).each {|i|
      yield(i)
    }
    end
    # Add a value at the end of the vector.
    # If second argument set to false, you should update the Vector usign
    # Vector.set_valid_data at the end of your insertion cycle
    #
    def add(v,update_valid=true)
      @data.push(v)
      set_valid_data if update_valid
    end
    # Update valid_data, missing_data, data_with_nils and gsl
    # at the end of an insertion.
    #
    # Use after Vector.add(v,false)
    # Usage:
    #   v=Statsample::Vector.new
    #   v.add(2,false)
    #   v.add(4,false)
    #   v.data
    #   => [2,3]
    #   v.valid_data
    #   => []
    #   v.set_valid_data
    #   v.valid_data
    #   => [2,3]
    def set_valid_data
      @valid_data.clear
      @missing_data.clear
      @data_with_nils.clear
      @date_data_with_nils.clear
      @gsl=nil
      set_valid_data_intern
      set_scale_data if(@type==:scale)
      set_date_data if(@type==:date)
    end
    if Statsample::STATSAMPLE__.respond_to?(:set_valid_data_intern)
      def set_valid_data_intern #:nodoc:
        Statsample::STATSAMPLE__.set_valid_data_intern(self)
      end
    else
      def set_valid_data_intern #:nodoc:
        _set_valid_data_intern                  
      end
    end
    def _set_valid_data_intern #:nodoc:
      @data.each do |n|
        if is_valid? n
          @valid_data.push(n)
          @data_with_nils.push(n)
        else
          @data_with_nils.push(nil)
          @missing_data.push(n)
        end
      end
      @has_missing_data=@missing_data.size>0
    end
    
    # Retrieves true if data has one o more missing values
    def has_missing_data?
      @has_missing_data
    end
    # Retrieves label for value x. Retrieves x if
    # no label defined.
    def labeling(x)
      @labels.has_key?(x) ? @labels[x].to_s : x.to_s
    end
    # Returns a Vector with data with labels replaced by the label.
    def vector_labeled
      d=@data.collect{|x|
        if @labels.has_key? x
          @labels[x]
        else
          x
        end
      }
      Vector.new(d,@type)
    end
    # Size of total data
    def size
      @data.size
    end
    alias_method :n, :size
    
    # Retrieves i element of data
    def [](i)
      @data[i]
    end
    # Set i element of data. 
    # Note: Use set_valid_data if you include missing values
    def []=(i,v)
      @data[i]=v
    end
    # Return true if a value is valid (not nil and not included on missing values)
    def is_valid?(x)
      !(x.nil? or @missing_values.include? x)
    end
    # Set missing_values.
    # if update_valid = false, you should use
    # set_valid_data after all changes
    def missing_values=(vals)
      @missing_values = vals
      set_valid_data
    end
    # Set data considered as "today" on data vectors
    def today_values=(vals)
      @today_values = vals
      set_valid_data
    end
    # Set level of measurement. 
    def type=(t)
      @type=t	
      set_scale_data if(t==:scale)
      set_date_data if (t==:date)
    end
    def to_a
      @data.dup
    end
    alias_method :to_ary, :to_a 
    
    # Vector sum. 
    # - If v is a scalar, add this value to all elements
    # - If v is a Array or a Vector, should be of the same size of this vector
    #   every item of this vector will be added to the value of the
    #   item at the same position on the other vector
    def +(v)
    _vector_ari("+",v)
    end
    # Vector rest. 
    # - If v is a scalar, rest this value to all elements
    # - If v is a Array or a Vector, should be of the same 
    #   size of this vector
    #   every item of this vector will be rested to the value of the
    #   item at the same position on the other vector
    
    def -(v)
    _vector_ari("-",v)
    end
    # Reports all values that doesn't comply with a condition.
    # Returns a hash with the index of data and the invalid data.
    def verify
    h={}
    (0...@data.size).to_a.each{|i|
      if !(yield @data[i])
        h[i]=@data[i]
      end
    }
    h
    end
    def _vector_ari(method,v) # :nodoc:
    if(v.is_a? Vector or v.is_a? Array)
      if v.size==@data.size
      #                    i=0
      sum=[]
      0.upto(v.size-1) {|i|
          if((v.is_a? Vector and v.is_valid?(v[i]) and is_valid?(@data[i])) or (v.is_a? Array and !v[i].nil? and !data[i].nil?))
              sum.push(@data[i].send(method,v[i]))
          else
              sum.push(nil)
          end
      }
      Statsample::Vector.new(sum, :scale  )
      else
      raise ArgumentError, "The array/vector parameter should be of the same size of the original vector"
      end
    elsif(v.respond_to? method )
      Statsample::Vector.new(
        @data.collect  {|x|
          if(!x.nil?)
            x.send(method,v)
          else
            nil
          end
        } , :scale)
    else
        raise TypeError,"You should pass a scalar or a array/vector"
    end
    
    end
    # Return an array with the data splitted by a separator.
    #   a=Vector.new(["a,b","c,d","a,b","d"])
    #   a.splitted
    #     =>
    #   [["a","b"],["c","d"],["a","b"],["d"]]
    def splitted(sep=Statsample::SPLIT_TOKEN)
    @data.collect{|x|
      if x.nil?
        nil
      elsif (x.respond_to? :split)
        x.split(sep)
      else
        [x]
      end
    }
    end
    # Returns a hash of Vectors, defined by the different values
    # defined on the fields
    # Example:
    #
    #  a=Vector.new(["a,b","c,d","a,b"])
    #  a.split_by_separator
    #  =>  {"a"=>#<Statsample::Type::Nominal:0x7f2dbcc09d88 
    #        @data=[1, 0, 1]>, 
    #       "b"=>#<Statsample::Type::Nominal:0x7f2dbcc09c48 
    #        @data=[1, 1, 0]>, 
    #      "c"=>#<Statsample::Type::Nominal:0x7f2dbcc09b08 
    #        @data=[0, 1, 1]>}
    #
    def split_by_separator(sep=Statsample::SPLIT_TOKEN)
    split_data=splitted(sep)
    factors=split_data.flatten.uniq.compact
    out=factors.inject({}) {|a,x|
      a[x]=[]
      a
    }
    split_data.each do |r|
      if r.nil?
        factors.each do |f|
          out[f].push(nil)
        end
      else
        factors.each do |f|
          out[f].push(r.include?(f) ? 1:0) 
        end
      end
    end
    out.inject({}){|s,v|
      s[v[0]]=Vector.new(v[1],:nominal)
      s
    }
    end
    def split_by_separator_freq(sep=Statsample::SPLIT_TOKEN)
    split_by_separator(sep).inject({}) {|a,v|
      a[v[0]]=v[1].inject {|s,x| s+x.to_i}
      a
    }
    end
    
    # Returns an random sample of size n, with replacement,
    # only with valid data.
    #
    # In all the trails, every item have the same probability
    # of been selected.
    def sample_with_replacement(sample=1)
      if(@type!=:scale or !Statsample.has_gsl?)
        vds=@valid_data.size
        (0...sample).collect{ @valid_data[rand(vds)] }
      else
        r = GSL::Rng.alloc(GSL::Rng::MT19937,rand(10000))
        r.sample(@gsl, sample).to_a
      end
    end
    # Returns an random sample of size n, without replacement,
    # only with valid data.
    #
    # Every element could only be selected once.
    # 
    # A sample of the same size of the vector is the vector itself.
      
    def sample_without_replacement(sample=1)
    if(@type!=:scale or !Statsample.has_gsl?)
      raise ArgumentError, "Sample size couldn't be greater than n" if sample>@valid_data.size
      out=[]
      size=@valid_data.size
      while out.size<sample
        value=rand(size)
        out.push(value) if !out.include?value
      end
      out.collect{|i|@data[i]}
    else
      r = GSL::Rng.alloc(GSL::Rng::MT19937,rand(10000))
      r.choose(@gsl, sample).to_a
    end
    end
    # Retrieves number of cases which comply condition.
    # If block given, retrieves number of instances where
    # block returns true.
    # If other values given, retrieves the frequency for
    # this value.
    def count(x=false)
    if block_given?
      r=@data.inject(0) {|s, i|
        r=yield i
        s+(r ? 1 : 0)
      }
      r.nil? ? 0 : r
    else
      frequencies[x].nil? ? 0 : frequencies[x]
    end
    end
    
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
    def can_be_scale?
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
    if @type==:scale
      @scale_data.uniq.sort
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
    
    # Returns the most frequent item.
    def mode
      frequencies.max{|a,b| a[1]<=>b[1]}[0]
    end
    # The numbers of item with valid data.
    def n_valid
      @valid_data.size
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
        s.text  _("factors:%s") % factors.join(",")
        s.text   _("mode: %s") % mode
        s.table(:name=>_("Distribution")) do |t|
          frequencies.sort.each do |k,v|
            key=labels.has_key?(k) ? labels[k]:k
            t.row [key, v , ("%0.2f%%" % (v.quo(n_valid)*100))]
          end
        end
        s.text _("median: %s") % median.to_s if(@type==:ordinal)
        if(@type==:scale)
          s.text _("mean: %0.4f") % mean
          s.text _("sd: %0.4f") % sd.to_s
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
      ### Ordinal Methods
      ######
    
      # Return the value of the percentil q
      def percentil(q)
        check_type :ordinal
        sorted=@valid_data.sort
        v= (n_valid * q).quo(100)
        if(v.to_i!=v)
          sorted[v.to_i]
        else
          (sorted[(v-0.5).to_i].to_f + sorted[(v+0.5).to_i]).quo(2)
        end
      end
      # Returns a ranked vector.
      def ranked(type=:ordinal)
        check_type :ordinal
        i=0
        r=frequencies.sort.inject({}){|a,v|
          a[v[0]]=(i+1 + i+v[1]).quo(2)
          i+=v[1]
          a
        }
        @data.collect {|c| r[c] }.to_vector(type)
      end
      # Return the median (percentil 50)
      def median
        check_type :ordinal
        if Statsample.has_gsl? and @type==:scale
          sorted=GSL::Vector.alloc(@scale_data.sort)
          GSL::Stats::median_from_sorted_data(sorted)
        else
          percentil(50)
        end
      end
      # Minimun value
      def min 
        check_type :ordinal
        @valid_data.min;
      end
        # Maximum value
      def max
        check_type :ordinal
        @valid_data.max;
      end
    
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
    
    def set_scale_data
      @scale_data=@valid_data.collect do|x|
        if x.is_a? Numeric
          x
        elsif x.is_a? String and x.to_i==x.to_f
          x.to_i
        else
          x.to_f
        end
      end
      if Statsample.has_gsl?
        @gsl=GSL::Vector.alloc(@scale_data) if @scale_data.size>0
      end
    end
    
    private :set_date_data, :set_scale_data
    
    # The range of the data (max - min)
    def range; 
      check_type :scale
      @scale_data.max - @scale_data.min
    end
    # The sum of values for the data
    def sum
      check_type :scale
      @scale_data.inject(0){|a,x|x+a} ; 
    end
    # The arithmetical mean of data
    def mean
      check_type :scale
      sum.to_f.quo(n_valid)
    end
    # Sum of squares for the data around a value.
    # By default, this value is the  mean
    #   ss= sum{(xi-m)^2}
    # 
    def sum_of_squares(m=nil)
      check_type :scale
      m||=mean
      @scale_data.inject(0){|a,x| a+(x-m).square}
    end
    # Sum of squared deviation
    def sum_of_squared_deviation
      check_type :scale
      @scale_data.inject(0) {|a,x| x.square+a} - (sum.square.quo(n_valid))
    end
    
    # Population variance (denominator N)
    def variance_population(m=nil)
      check_type :scale
      m||=mean
      squares=@scale_data.inject(0){|a,x| x.square+a}
      squares.quo(n_valid) - m.square
    end
    
    
    # Population Standard deviation (denominator N)
    def standard_deviation_population(m=nil)
      check_type :scale
      Math::sqrt( variance_population(m) )
    end

    # Population average deviation (denominator N)
    def average_deviation_population( m = nil )
      check_type :scale
      m ||= mean
      ( @scale_data.inject( 0 ) { |a, x| ( x - m ).abs + a } ).quo( n_valid )
    end

    # Sample Variance (denominator n-1)
    def variance_sample(m=nil)
      check_type :scale
      m||=mean
      sum_of_squares(m).quo(n_valid - 1)
    end
    
    # Sample Standard deviation (denominator n-1)
    def standard_deviation_sample(m=nil)
        check_type :scale
        
        m||=mean
        Math::sqrt(variance_sample(m))
    end
    # Skewness of the sample
    def skew(m=nil)
        check_type :scale
        m||=mean
        th=@scale_data.inject(0){|a,x| a+((x-m)**3)}
        th.quo((@scale_data.size)*sd(m)**3)
    end
    # Kurtosis of the sample
    def kurtosis(m=nil)
        check_type :scale
        m||=mean
        fo=@scale_data.inject(0){|a,x| a+((x-m)**4)}
        fo.quo((@scale_data.size)*sd(m)**4)-3
        
    end
    # Product of all values on the sample
    # 
    def product
        check_type :scale
        @scale_data.inject(1){|a,x| a*x }
    end
    if Statsample.has_gsl?
      %w{skew kurtosis variance_sample standard_deviation_sample variance_population standard_deviation_population mean sum}.each{|m|
          m_nuevo=(m+"_slow").intern
          alias_method m_nuevo, m.intern
      }
      def sum # :nodoc:
      check_type :scale
          
          @gsl.sum
      end
      def mean # :nodoc:
      check_type :scale
        @gsl.nil? ? nil : @gsl.mean
      end				
      def variance_sample(m=nil) # :nodoc:
          check_type :scale
          m||=mean
          @gsl.variance_m
      end
      def standard_deviation_sample(m=nil) # :nodoc:
          check_type :scale
          return nil if @gsl.nil?
          m||=mean
          @gsl.sd(m)
      end
      
      def variance_population(m=nil) # :nodoc:
      check_type :scale    
          m||=mean
          @gsl.variance_with_fixed_mean(m)
      end
      def standard_deviation_population(m=nil) # :nodoc:
          check_type :scale
          m||=mean
          @gsl.sd_with_fixed_mean(m)
      end
      def skew # :nodoc:
          check_type :scale
          @gsl.skew
      end
      def kurtosis # :nodoc:
          check_type :scale
          @gsl.kurtosis
      end
      # Create a GSL::Histogram
      # With a fixnum, creates X bins within the range of data
      # With an Array, each value will be a cut point
      def histogram(bins=10)
        check_type :scale
        
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
      
    end
      
    # Coefficient of variation
    # Calculed with the sample standard deviation
    def coefficient_of_variation
        check_type :scale
        standard_deviation_sample.quo(mean)
    end
    
    alias_method :sdp, :standard_deviation_population
    alias_method :sds, :standard_deviation_sample
    alias_method :adp, :average_deviation_population
    alias_method :cov, :coefficient_of_variation
    alias_method :variance, :variance_sample    
    alias_method :sd, :standard_deviation_sample
    alias_method :ss, :sum_of_squares
  end
end
