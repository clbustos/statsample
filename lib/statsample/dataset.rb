require 'statsample/vector'

class Hash
  # Creates a Statsample::Dataset based on a Hash 
  def to_dataset(*args)
    Statsample::Dataset.new(self, *args)
  end
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
  class DatasetException < RuntimeError # :nodoc:
    attr_reader :ds,:exp
    def initialize(ds,e)
      @ds=ds
      @exp=e
    end
    def to_s
      m="Error on iteration: "+@exp.message+"\n"+@exp.backtrace.join("\n")
      m+="\nRow: #{@ds.i}" unless @ds.i.nil?
      m
    end
  end
  # Set of cases with values for one or more variables, 
  # analog to a dataframe on R or a standard data file of SPSS.
  # Every vector has <tt>#field</tt> name, which represent it. By default,
  # the vectors are ordered by it field name, but you can change it 
  # the fields order manually.
  # The Dataset work as a Hash, with keys are field names
  # and values are Statsample::Vector  
  # 
  # 
  # ==Usage
  # Create a empty dataset:
  #   Dataset.new()
  # Create a dataset with three empty vectors, called <tt>v1</tt>, <tt>v2</tt> and <tt>v3</tt>:
  #   Dataset.new(%w{v1 v2 v3})
  # Create a dataset with two vectors, called <tt>v1</tt>
  # and <tt>v2</tt>:
  #   Dataset.new({'v1'=>%w{1 2 3}.to_vector, 'v2'=>%w{4 5 6}.to_vector})
  # Create a dataset with two given vectors (v1 and v2), 
  # with vectors on inverted order:
  #   Dataset.new({'v2'=>v2,'v1'=>v1},['v2','v1'])
  #
  # The fast way to create a dataset uses Hash#to_dataset, with
  # field order  as arguments
  #   v1 = [1,2,3].to_scale
  #   v2 = [1,2,3].to_scale
  #   ds = {'v1'=>v2, 'v2'=>v2}.to_dataset(%w{v2 v1})  
  
  class Dataset
    include Writable
    include Summarizable
    # Hash of Statsample::Vector
    attr_reader :vectors
    # Ordered ids of vectors
    attr_reader :fields
    # Name of dataset
    attr_accessor :name
    # Number of cases
    attr_reader :cases
    # Location of pointer on enumerations methods (like #each)
    attr_reader :i

    # Generates a new dataset, using three vectors
    # - Rows
    # - Columns
    # - Values
    #
    # For example, you have these values
    #
    #   x   y   v
    #   a   a   0
    #   a   b   1
    #   b   a   1
    #   b   b   0
    #
    # You obtain
    #   id  a   b
    #    a  0   1
    #    b  1   0
    #
    # Useful to process outputs from databases
    def self.crosstab_by_asignation(rows,columns,values)
      raise "Three vectors should be equal size" if rows.size!=columns.size or rows.size!=values.size
      cols_values=columns.factors
      cols_n=cols_values.size
      h_rows=rows.factors.inject({}){|a,v| a[v]=cols_values.inject({}){
        |a1,v1| a1[v1]=nil; a1
        }
        ;a}
      values.each_index{|i|
        h_rows[rows[i]][columns[i]]=values[i]
      }      
      ds=Dataset.new(["_id"]+cols_values)
      cols_values.each{|c|
        ds[c].type=values.type
      }
      rows.factors.each {|row|
        n_row=Array.new(cols_n+1)
        n_row[0]=row
          cols_values.each_index {|i|
            n_row[i+1]=h_rows[row][cols_values[i]]
        }
        ds.add_case_array(n_row)
      }
      ds.update_valid_data
      ds
    end
    # Creates a new dataset. A dataset is a set of ordered named vectors
    # of the same size.
    #
    # [vectors] With an array, creates a set of empty vectors named as
    # values on the array. With a hash, each Vector is assigned as
    # a variable of the Dataset named as its key
    # [fields]  Array of names for vectors. Is only used for set the
    # order of variables. If empty, vectors keys on alfabethic order as
    # used as fields.
    def initialize(vectors={}, fields=[])
      @@n_dataset||=0
      @@n_dataset+=1
      @name=_("Dataset %d") % @@n_dataset
      if vectors.instance_of? Array
        @fields=vectors.dup
        @vectors=vectors.inject({}){|a,x| a[x]=Statsample::Vector.new(); a}
      else
        # Check vectors
        @vectors=vectors
        @fields=fields
        check_order
        check_length
      end
      @i=nil
    end
    #
    # Returns a GSL::matrix
    #
    def to_gsl_matrix
      matrix=GSL::Matrix.alloc(cases,@vectors.size)
      each_array do |row|
        row.each_index{|y| matrix.set(@i,y,row[y]) }
      end
      matrix
    end
    # 
    # Creates a copy of the given dataset, deleting all the cases with
    # missing data on one of the vectors.
    # 
    # @param array of fields to include. No value include all fields
    #
    def dup_only_valid(*fields_to_include)
      if fields_to_include.size==1 and fields_to_include[0].is_a? Array
        fields_to_include=fields_to_include[0]
      end
      fields_to_include=@fields if fields_to_include.size==0
      if fields_to_include.any? {|f| @vectors[f].has_missing_data?}
        ds=Dataset.new(fields_to_include)
        fields_to_include.each {|f| ds[f].type=@vectors[f].type}
        each {|row|
          unless fields_to_include.any? {|f| @vectors[f].has_missing_data? and !@vectors[f].is_valid? row[f]}
            row_2=fields_to_include.inject({}) {|ac,v| ac[v]=row[v]; ac}
            ds.add_case(row_2)
          end
        }
      else
        ds=dup fields_to_include
      end
      ds
    end
    #
    # Returns a duplicate of the Dataset. 
    # All vectors are copied, so any modification on new
    # dataset doesn't affect original dataset's vectors.
    # If fields given as parameter, only include those vectors.
    #
    # @param array of fields to include. No value include all fields    
    # @return {Statsample::Dataset}
    def dup(*fields_to_include)
      if fields_to_include.size==1 and fields_to_include[0].is_a? Array
        fields_to_include=fields_to_include[0]
      end
      fields_to_include=@fields if fields_to_include.size==0
      vectors={}
      fields=[]
      fields_to_include.each{|f|
        raise "Vector #{f} doesn't exists" unless @vectors.has_key? f
        vectors[f]=@vectors[f].dup
        fields.push(f)
      }
      Dataset.new(vectors,fields)
    end
    
    
    # Returns an array with the fields from first argumen to last argument
    def from_to(from,to)
      raise ArgumentError, "Field #{from} should be on dataset" if !@fields.include? from
      raise ArgumentError, "Field #{to} should be on dataset" if !@fields.include? to
      @fields.slice(@fields.index(from)..@fields.index(to))
    end
    
    # Returns (when possible) a cheap copy of dataset.
    # If no vector have missing values, returns original vectors.
    # If missing values presents, uses Dataset.dup_only_valid.
    #
    # @param array of fields to include. No value include all fields
    # @return {Statsample::Dataset}
    def clone_only_valid(*fields_to_include)
      if fields_to_include.size==1 and fields_to_include[0].is_a? Array
        fields_to_include=fields_to_include[0]
      end
      fields_to_include=@fields.dup if fields_to_include.size==0
      if fields_to_include.any? {|v| @vectors[v].has_missing_data?}
        dup_only_valid(fields_to_include)
      else
        clone(fields_to_include)
      end
    end
    # Returns a shallow copy of Dataset.
    # Object id will be distinct, but @vectors will be the same.
    # @param array of fields to include. No value include all fields
    # @return {Statsample::Dataset}    
    def clone(*fields_to_include)
      if fields_to_include.size==1 and fields_to_include[0].is_a? Array
        fields_to_include=fields_to_include[0]
      end
      fields_to_include=@fields.dup if fields_to_include.size==0
      ds=Dataset.new
      fields_to_include.each{|f|
        raise "Vector #{f} doesn't exists" unless @vectors.has_key? f
        ds[f]=@vectors[f]
      }
      ds.fields=fields_to_include
      ds.name=@name
      ds.update_valid_data
      ds
    end
    # Creates a copy of the given dataset, without data on vectors
    #
    # @return {Statsample::Dataset}
    def dup_empty
      vectors=@vectors.inject({}) {|a,v|
        a[v[0]]=v[1].dup_empty
        a
      }
      Dataset.new(vectors,@fields.dup)
    end
    # Merge vectors from two datasets
    # In case of name collition, the vectors names are changed to 
    # x_1, x_2 ....
    #
    # @return {Statsample::Dataset}
    def merge(other_ds)
      raise "Cases should be equal (this:#{@cases}; other:#{other_ds.cases}" unless @cases==other_ds.cases
      types = @fields.collect{|f| @vectors[f].type} + other_ds.fields.collect{|f| other_ds[f].type}
      new_fields = (@fields+other_ds.fields).recode_repeated
      ds_new=Statsample::Dataset.new(new_fields)
      new_fields.each_index{|i|
        field=new_fields[i]
        ds_new[field].type=types[i]
      }
      @cases.times {|i|
        row=case_as_array(i)+other_ds.case_as_array(i)
        ds_new.add_case_array(row)
      }
      ds_new.update_valid_data
      ds_new
    end
    # Returns a dataset with standarized data.
    #
    # @return {Statsample::Dataset}
    def standarize
      ds=dup()
      ds.fields.each do |f|
        ds[f]=ds[f].vector_standarized
      end
      ds
    end
    # Generate a matrix, based on fields of dataset
    #
    # @return {::Matrix}
    
    def collect_matrix
      rows=@fields.collect{|row|
        @fields.collect{|col|
          yield row,col
        }
      }
      Matrix.rows(rows)
    end
    
    # We have the same datasets if +vectors+ and +fields+ are the same
    #
    # @return {Boolean}
    def ==(d2)
      @vectors==d2.vectors and @fields==d2.fields
    end
    # Returns vector <tt>c</tt>
    # 
    # @return {Statsample::Vector}
    def col(c)
      @vectors[c]
    end
    alias_method :vector, :col
    # Equal to Dataset[<tt>name</tt>]=<tt>vector</tt>
    #
    # @return self
    def add_vector(name, vector)
      raise ArgumentError, "Vector have different size" if vector.size!=@cases
      @vectors[name]=vector
      check_order
      self
    end
    # Returns true if dataset have vector <tt>v</tt>.
    #
    # @return {Boolean}
    def has_vector? (v)
      return @vectors.has_key?(v)
    end
    # Creates a dataset with the random data, of a n size
    # If n not given, uses original number of cases.
    #
    # @return {Statsample::Dataset}
    def bootstrap(n=nil)
      n||=@cases
      ds_boot=dup_empty
      n.times do
        ds_boot.add_case_array(case_as_array(rand(n)))
      end
      ds_boot.update_valid_data
      ds_boot
    end
    # Fast version of #add_case.
    # Can only add one case and no error check if performed
    # You SHOULD use #update_valid_data at the end of insertion cycle
    #
    # 
    def add_case_array(v)
      v.each_index {|i| d=@vectors[@fields[i]].data; d.push(v[i])}
    end
    # Insert a case, using:
    # * Array: size equal to number of vectors and values in the same order as fields
    # * Hash: keys equal to fields
    # If uvd is false, #update_valid_data is not executed after 
    # inserting a case. This is very useful if you want to increase the 
    # performance on inserting many cases,  because #update_valid_data 
    # performs check on vectors and on the dataset
    
    def add_case(v,uvd=true)
      case v
      when Array
        if (v[0].is_a? Array)
          v.each{|subv| add_case(subv,false)}
        else
          raise ArgumentError, "Input array size (#{v.size}) should be equal to fields number (#{@fields.size})" if @fields.size!=v.size
          v.each_index {|i| @vectors[@fields[i]].add(v[i],false)}
        end
      when Hash
        raise ArgumentError, "Hash keys should be equal to fields #{(v.keys - @fields).join(",")}" if @fields.sort!=v.keys.sort
        @fields.each{|f| @vectors[f].add(v[f],false)}
      else
        raise TypeError, 'Value must be a Array or a Hash'
      end
      if uvd
        update_valid_data
      end
    end
    # Check vectors and fields after inserting data. Use only 
    # after  #add_case_array or #add_case with second parameter to false
    def update_valid_data
      @fields.each{|f| @vectors[f].set_valid_data}
      check_length
    end
    # Delete vector named +name+. Multiple fields accepted.
    def delete_vector(*args)
      if args.size==1 and args[0].is_a? Array
        names=args[0]
      else
        names=args
      end
      names.each do |name|
        @fields.delete(name)
        @vectors.delete(name)
      end
    end
    
    def add_vectors_by_split_recode(name_,join='-',sep=Statsample::SPLIT_TOKEN)
      split=@vectors[name_].split_by_separator(sep)
      i=1
      split.each{|k,v|
        new_field=name_+join+i.to_s
        v.name=name_+":"+k
        add_vector(new_field,v)
        i+=1
      }
    end
    def add_vectors_by_split(name,join='-',sep=Statsample::SPLIT_TOKEN)
      split=@vectors[name].split_by_separator(sep)
      split.each{|k,v|
        add_vector(name+join+k,v)
      }
    end
    
    def vector_by_calculation(type=:scale)
      a=[]
      each do |row|
        a.push(yield(row))
      end
      a.to_vector(type)
    end
    # Returns a vector with sumatory of fields
    # if fields parameter is empty, sum all fields 
    def vector_sum(fields=nil)
      fields||=@fields
      vector=collect_with_index do |row, i|
        if(fields.find{|f| !@vectors[f].data_with_nils[i]})
          nil
        else
          fields.inject(0) {|ac,v| ac + row[v].to_f}
        end
      end
      vector.name=_("Sum from %s") % @name
      vector
    end
    # Check if #fields attribute is correct, after inserting or deleting vectors
    def check_fields(fields)
      fields||=@fields
      raise "Fields #{(fields-@fields).join(", ")} doesn't exists on dataset" if (fields-@fields).size>0
      fields
    end
    
    # Returns a vector with the numbers of missing values for a case
    def vector_missing_values(fields=nil)
      fields=check_fields(fields)
      collect_with_index do |row, i|
        fields.inject(0) {|a,v|
          a+ ((@vectors[v].data_with_nils[i].nil?) ? 1: 0)
        }
      end
    end
    def vector_count_characters(fields=nil)
      fields=check_fields(fields)
      collect_with_index do |row, i|
        fields.inject(0){|a,v|
          a+((@vectors[v].data_with_nils[i].nil?) ? 0: row[v].to_s.size)
        }
      end
    end
    # Returns a vector with the mean for a set of fields
    # if fields parameter is empty, return the mean for all fields
    # if max invalid parameter > 0, returns the mean for all tuples
    # with 0 to max_invalid invalid fields
    def vector_mean(fields=nil, max_invalid=0)
      a=[]
      fields=check_fields(fields)
      size=fields.size
      each_with_index do |row, i |
        # numero de invalidos
        sum=0
        invalids=0
        fields.each{|f|
          if !@vectors[f].data_with_nils[i].nil?
            sum+=row[f].to_f
          else
            invalids+=1
          end
        }
        if(invalids>max_invalid)
          a.push(nil)
        else
          a.push(sum.quo(size-invalids))
        end
      end
      a=a.to_vector(:scale)
      a.name=_("Means from %s") % @name
      a
    end
    # Check vectors for type and size.
    def check_length # :nodoc:
      size=nil
      @vectors.each do |k,v|
        raise Exception, "Data #{v.class} is not a vector on key #{k}" if !v.is_a? Statsample::Vector
        if size.nil?
          size=v.size
        else
          if v.size!=size
            p v.to_a.size
            raise Exception, "Vector #{k} have size #{v.size} and dataset have size #{size}"
          end
        end
      end
      @cases=size
    end
    # Retrieves each vector as [key, vector]
    def each_vector # :yield: |key, vector|
      @fields.each{|k| yield k, @vectors[k]}
    end
    
    if Statsample::STATSAMPLE__.respond_to?(:case_as_hash)
      def case_as_hash(c) # :nodoc:
        Statsample::STATSAMPLE__.case_as_hash(self,c)
      end
    else
      # Retrieves case i as a hash
      def case_as_hash(i)
        _case_as_hash(i)
      end
    end

    if Statsample::STATSAMPLE__.respond_to?(:case_as_array)
      def case_as_array(c) # :nodoc:
        Statsample::STATSAMPLE__.case_as_array(self,c)
      end
    else
      # Retrieves case i as a array, ordered on #fields order
      def case_as_array(i)
        _case_as_array(i)
      end
    end
    def _case_as_hash(c) # :nodoc:
      @fields.inject({}) {|a,x| a[x]=@vectors[x][c];a }
    end
    def _case_as_array(c) # :nodoc:
      @fields.collect {|x| @vectors[x][c]}
    end
    
    # Returns each case as a hash
    def each
      begin
        @i=0
        @cases.times {|i|
          @i=i
          row=case_as_hash(i)
          yield row
        }
        @i=nil
      rescue =>e
        raise DatasetException.new(self, e)
      end
    end
    
    # Returns each case as hash and index
    def each_with_index # :yield: |case, i|
      begin
        @i=0
        @cases.times{|i|
          @i=i
          row=case_as_hash(i)
          yield row, i
        }
        @i=nil
      rescue =>e
        raise DatasetException.new(self, e)
      end
    end
    
    # Returns each case as an array, coding missing values as nils
    def each_array_with_nils
      m=fields.size
      @cases.times {|i|
        @i=i
        row=Array.new(m)
        fields.each_index{|j|
          f=fields[j]
          row[j]=@vectors[f].data_with_nils[i]
        }
        yield row
      }
      @i=nil
    end
    # Returns each case as an array
    def each_array
      @cases.times {|i|
        @i=i
        row=case_as_array(i)
        yield row
      }
      @i=nil
    end
    # Set fields order. If you omit one or more vectors, they are
    # ordered by alphabetic order.
    def fields=(f)
      @fields=f
      check_order
    end
    # Check congruence between +fields+ attribute
    # and keys on +vectors
    def check_order #:nodoc:
      if(@vectors.keys.sort!=@fields.sort)
        @fields=@fields&@vectors.keys
        @fields+=@vectors.keys.sort-@fields
      end
    end
    # Returns the vector named i
    def[](i)
      if i.is_a? Range
        fields=from_to(i.begin,i.end)
        clone(*fields)
      else
        raise Exception,"Vector '#{i}' doesn't exists on dataset" unless @vectors.has_key?(i)
        @vectors[i]
      end
    end
    # Retrieves a Statsample::Vector, based on the result
    # of calculation performed on each case.
    def collect(type=:scale)
      data=[]
      each {|row|
        data.push yield(row)
      }
      Statsample::Vector.new(data,type)
    end
    # Same as Statsample::Vector.collect, but giving case index as second parameter on yield.
    def collect_with_index(type=:scale)
      data=[]
      each_with_index {|row, i|
        data.push(yield(row, i))
      }
      Statsample::Vector.new(data,type)
    end
    # Recode a vector based on a block
    def recode!(vector_name)
      
      0.upto(@cases-1) {|i|
        @vectors[vector_name].data[i]=yield case_as_hash(i)
      }
      @vectors[vector_name].set_valid_data
    end
    
    def crosstab(v1,v2,opts={})
      Statsample::Crosstab.new(@vectors[v1], @vectors[v2],opts)
    end
    def[]=(i,v)
      if v.instance_of? Statsample::Vector
        @vectors[i]=v
        check_order
      else
        raise ArgumentError,"Should pass a Statsample::Vector"
      end
    end
    # Return data as a matrix. Column are ordered by #fields and 
    # rows by orden of insertion
    def to_matrix
      rows=[]
      self.each_array{|c|
        rows.push(c)
      }
      Matrix.rows(rows)
    end
    
    if Statsample.has_gsl?
      def to_matrix_gsl
      rows=[]
      self.each_array{|c|
        rows.push(c)
      }
      GSL::Matrix.alloc(*rows)
      end
    end
    # Return a correlation matrix for fields included as parameters.
    # By default, uses all fields of dataset
		def correlation_matrix(fields=nil)
      if fields
        ds=clone(fields)
      else
        ds=self
      end
      Statsample::Bivariate.correlation_matrix(ds)
    end
   
    
    # Create a new dataset with all cases which the block returns true
    def filter
      ds=self.dup_empty
      each {|c|
        ds.add_case(c, false) if yield c
      }
      ds.update_valid_data
      ds.name=_("%s(filtered)") % @name
      ds
    end
    
    # creates a new vector with the data of a given field which the block returns true
    def filter_field(field)
      a=[]
      each do |c|
        a.push(c[field]) if yield c
      end
      a.to_vector(@vectors[field].type)
    end
    
    # Creates a Stastample::Multiset, using one or more fields
    # to split the dataset.
    
   
    def to_multiset_by_split(*fields)
			require 'statsample/multiset'
			if fields.size==1
				to_multiset_by_split_one_field(fields[0])
			else
				to_multiset_by_split_multiple_fields(*fields)
			end
    end
    # Creates a Statsample::Multiset, using one field
    
    def to_multiset_by_split_one_field(field)
      raise ArgumentError,"Should use a correct field name" if !@fields.include? field
      factors=@vectors[field].factors
      ms=Multiset.new_empty_vectors(@fields, factors)
      each {|c|
        ms[c[field]].add_case(c,false)
      }
      #puts "Ingreso a los dataset"
      ms.datasets.each {|k,ds|
        ds.update_valid_data
        ds.name=@vectors[field].labeling(k)
        ds.vectors.each{|k1,v1|
          #        puts "Vector #{k1}:"+v1.to_s
          v1.type=@vectors[k1].type
          v1.name=@vectors[k1].name
        }
      }
      ms
    end
    def to_multiset_by_split_multiple_fields(*fields)
      factors_total=nil
      fields.each do |f|
        if factors_total.nil?
          factors_total=@vectors[f].factors.collect{|c|
            [c]
          }
        else
          suma=[]
          factors=@vectors[f].factors
          factors_total.each{|f1| factors.each{|f2| suma.push(f1+[f2]) } }
          factors_total=suma
        end
      end
      ms=Multiset.new_empty_vectors(@fields,factors_total)

      p1=eval "Proc.new {|c| ms[["+fields.collect{|f| "c['#{f}']"}.join(",")+"]].add_case(c,false) }"
      each{|c| p1.call(c)}
      
      ms.datasets.each do |k,ds|
        ds.update_valid_data
        ds.name=fields.size.times.map {|i|
          f=fields[i]
          sk=k[i]
          @vectors[f].labeling(sk)
        }.join("-")
        ds.vectors.each{|k1,v1| 
          v1.type=@vectors[k1].type
          v1.name=@vectors[k1].name
        }
      end
      ms
      
    end
    # Returns a vector, based on a string with a calculation based
    # on vector
    # The calculation will be eval'ed, so you can put any variable
    # or expression valid on ruby
    # For example:
    #   a=[1,2].to_vector(scale)
    #   b=[3,4].to_vector(scale)
    #   ds={'a'=>a,'b'=>b}.to_dataset
    #   ds.compute("a+b")
    #   => Vector [4,6]
    def compute(text)
      @fields.each{|f|
        if @vectors[f].type=:scale
          text.gsub!(f,"row['#{f}'].to_f")
        else
          text.gsub!(f,"row['#{f}']")
        end
      }
      collect_with_index {|row, i|
        invalid=false
        @fields.each{|f|
          if @vectors[f].data_with_nils[i].nil?
            invalid=true
          end
        }
        if invalid
          nil
        else
          eval(text)
        end
      }
    end
    # Test each row with one or more tests
    # each test is a Proc with the form
    #   Proc.new {|row| row['age']>0}
    # The function returns an array with all errors
    def verify(*tests)
      if(tests[0].is_a? String)
        id=tests[0]
        tests.shift
      else
        id=@fields[0]
      end
      vr=[]
      i=0
      each do |row|
        i+=1
        tests.each{|test|
          if ! test[2].call(row)
            values=""
            if test[1].size>0
              values=" ("+test[1].collect{|k| "#{k}=#{row[k]}"}.join(", ")+")"
            end
            vr.push("#{i} [#{row[id]}]: #{test[0]}#{values}")
          end
        }
      end
      vr
    end
    def to_s
      "#<"+self.class.to_s+":"+self.object_id.to_s+" @name=#{@name} @fields=["+@fields.join(",")+"] cases="+@vectors[@fields[0]].size.to_s
    end
    def inspect
      self.to_s
    end
    # Creates a new dataset for one to many relations
    # on a dataset, based on pattern of field names.
    # 
    # for example, you have a survey for number of children
    # with this structure:
    #   id, name, child_name_1, child_age_1, child_name_2, child_age_2
    # with 
    #   ds.one_to_many(%w{id}, "child_%v_%n"
    # the field of first parameters will be copied verbatim
    # to new dataset, and fields which responds to second 
    # pattern will be added one case for each different %n.
    # For example
    #   cases=[
    #     ['1','george','red',10,'blue',20,nil,nil],
    #     ['2','fred','green',15,'orange',30,'white',20],
    #     ['3','alfred',nil,nil,nil,nil,nil,nil]
    #   ]
    #   ds=Statsample::Dataset.new(%w{id name car_color1 car_value1 car_color2 car_value2 car_color3 car_value3})
    #   cases.each {|c| ds.add_case_array c }
    #   ds.one_to_many(['id'],'car_%v%n').to_matrix
    #   => Matrix[
    #      ["red", "1", 10], 
    #      ["blue", "1", 20],
    #      ["green", "2", 15],
    #      ["orange", "2", 30],
    #      ["white", "2", 20]
    #      ]
    # 
    def one_to_many(parent_fields, pattern)
      #base_pattern=pattern.gsub(/%v|%n/,"")
      re=Regexp.new pattern.gsub("%v","(.+?)").gsub("%n","(\\d+?)")
      ds_vars=parent_fields
      vars=[]
      max_n=0
      h=parent_fields.inject({}) {|a,v| a[v]=Statsample::Vector.new([], @vectors[v].type);a }
      # Adding _row_id
      h['_col_id']=[].to_scale
      ds_vars.push("_col_id")
      @fields.each do |f|
        if f=~re
          if !vars.include? $1
            vars.push($1) 
            h[$1]=Statsample::Vector.new([], @vectors[f].type)
          end
          max_n=$2.to_i if max_n < $2.to_i
        end
      end
      ds=Dataset.new(h,ds_vars+vars)
      each do |row|
        row_out={}
        parent_fields.each do |f|
          row_out[f]=row[f]
        end
        max_n.times do |n1|
          n=n1+1
          any_data=false
          vars.each do |v|
            data=row[pattern.gsub("%v",v.to_s).gsub("%n",n.to_s)]
            row_out[v]=data
            any_data=true if !data.nil?
          end
          if any_data
            row_out["_col_id"]=n
            ds.add_case(row_out,false)
          end
          
        end
      end
      ds.update_valid_data
      ds
    end
    def report_building(b)
      b.section(:name=>@name) do |g|
        g.text _"Cases: %d"  % cases
        @fields.each do |f|
          g.text "Element:[#{f}]"
          g.parse_element(@vectors[f])
        end
      end
    end
  end
end
