require 'statsample/vector'

class Hash
  def to_dataset(*args)
    Statsample::Dataset.new(self,*args)
  end
end

class Array
  def prefix(s)
    self.collect{|c| s+c.to_s }
  end
  def suffix(s)
    self.collect{|c| c.to_s+s }
  end
end

module Statsample
  class DatasetException < RuntimeError
    attr_reader :ds,:exp
    def initialize(ds,e)
      @ds=ds
      @exp=e
    end
    def to_s
      m="Error: "+@exp.message+"\n"+@exp.backtrace.join("\n")+"\nOn Dataset:"+@ds.inspect
      m+="\nRow: #{@i}" unless @i.nil?
      m
    end
  end
  class Dataset
    include Writable
    attr_reader :vectors, :fields, :cases, :i
    attr_accessor :labels
    
    # Generates a new dataset, using three vectors
    # - Rows
    # - Columns
    # - Values
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
    #    
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
    # used as fields
    # [labels]  Hash to set names for fields.
    #
    #
    #   Dataset.new()
    #   Dataset.new(%w{v1 v2 v3})
    #   Dataset.new({'v1'=>%w{1 2 3}.to_vector, 'v2'=>%w{4 5 6}.to_vector})
    #   Dataset.new({'v2'=>v2,'v1'=>v1},['v1','v2'])
    #
    # The fast way to create a dataset uses Hash#to_dataset, with
    # fields and labels as arguments
    #   ds = {'v1'=>[1,2,3].to_vector}.to_dataset
    #
    def initialize(vectors={}, fields=[], labels={})
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
      @labels=labels
    end
    def to_gsl_matrix
      matrix=GSL::Matrix.alloc(cases,@vectors.size)
      each_array do |row|
        row.each_index{|y| matrix.set(@i,y,row[y]) }
      end
      matrix
    end
    def vector_label(v_id)
      raise "Vector #{v} doesn't exists" unless @fields.include? v_id
      @labels[v_id].nil? ? v_id : @labels[v_id]
    end
    # Creates a copy of the given dataset, deleting all the cases with
    # missing data on one of the vectors
    def dup_only_valid
      if @vectors.find{|field,vector| vector.has_missing_data?}
        ds=dup_empty
        each_array { |c|
          ds.add_case_array(c) unless @fields.find{|f| @vectors[f].data_with_nils[@i].nil? }
        }
        ds.update_valid_data
      else
        ds=dup()
      end
      ds
    end
    # Returns an array with the fields from first argumen to last argument
    def from_to(from,to)
      raise ArgumentError, "Field #{from} should be on dataset" if !@fields.include? from
      raise ArgumentError, "Field #{to} should be on dataset" if !@fields.include? to
      @fields.slice(@fields.index(from)..@fields.index(to))
    end
    # Returns a duplicate of the Database
    # If fields given, only include those vectors
    def dup(*fields_to_include)
      if fields_to_include.size==1 and fields_to_include[0].is_a? Array
        fields_to_include=fields_to_include[0]
      end
      fields_to_include=@fields if fields_to_include.size==0
      vectors={}
      fields=[]
      new_labels={}
      fields_to_include.each{|f|
        raise "Vector #{f} doesn't exists" unless @vectors.has_key? f
        vectors[f]=@vectors[f].dup
        new_labels[f]=@labels[f]
        fields.push(f)
      }
      Dataset.new(vectors,fields,new_labels)
    end
    # Creates a copy of the given dataset, without data on vectors
    def dup_empty
      vectors=@vectors.inject({}) {|a,v|
        a[v[0]]=v[1].dup_empty
        a
      }
      Dataset.new(vectors,@fields.dup,@labels.dup)
    end
    # Merge vectors from two datasets
    # In case of name collition, the vectors names are changed to 
    # x_1, x_2 ....
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
    # Returns a dataset with standarized data
	def standarize
	  ds=dup()
	  ds.fields.each {|f|
		ds[f]=ds[f].vector_standarized
	  }
	  ds
	end
    # Generate a matrix, based on fields of dataset
    def collect_matrix
      rows=@fields.collect{|row|
        @fields.collect{|col|
          yield row,col
        }
      }
      Matrix.rows(rows)
    end
    # We have the same datasets if the labels and vectors are the same
    def ==(d2)
      @vectors==d2.vectors and @fields==d2.fields
    end
    def col(c)
      @vectors[c]
    end
    alias_method :vector, :col
    def add_vector(name,vector)
      raise ArgumentError, "Vector have different size" if vector.size!=@cases
      @vectors[name]=vector
      check_order
    end
    def has_vector? (v)
      return @vectors.has_key?(v)
    end
    # Creates a dataset with the random data, of a n size
    # If n not given, uses original number of cases
    def bootstrap(n=nil)
      n||=@cases
      ds_boot=dup_empty
      for i in 1..n
        ds_boot.add_case_array(case_as_array(rand(n)))
      end
      ds_boot.update_valid_data
      ds_boot
    end
    # Fast version of add case
    # Can only add one case and no error check if performed
    # You SHOULD use update_valid_data at the end of insertion cycle
    def add_case_array(v)
      v.each_index {|i| d=@vectors[@fields[i]].data; d.push(v[i])}
    end
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
    def update_valid_data
      @fields.each{|f| @vectors[f].set_valid_data}
      check_length
    end
    def delete_vector(name)
      @fields.delete(name)
      @vectors.delete(name)
    end
    def add_vectors_by_split_recode(name,join='-',sep=Statsample::SPLIT_TOKEN)
      split=@vectors[name].split_by_separator(sep)
      i=1
      split.each{|k,v|
        new_field=name+join+i.to_s
        @labels[new_field]=name+":"+k
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
			each {|row|
				a.push(yield(row))
			}
			a.to_vector(type)
		end
		# Returns a vector with sumatory of fields
		# if fields parameter is empty, sum all fields 
		def vector_sum(fields=nil)
			a=[]
			fields||=@fields
			collect_with_index do |i,row|
				if(fields.find{|f| !@vectors[f].data_with_nils[i]})
					nil
				else
					fields.inject(0) {|ac,v| ac + row[v].to_f}
				end
      end
		end
    def check_fields(fields)
      fields||=@fields
      raise "Fields #{(fields-@fields).join(", ")} doesn't exists on dataset" if (fields-@fields).size>0
      fields
    end
    # Returns a vector with the numbers of missing values for a case

    def vector_missing_values(fields=nil)
      fields=check_fields(fields)
      collect_with_index do |i,row|
        fields.inject(0) {|a,v|
          a+ ((@vectors[v].data_with_nils[i].nil?) ? 1: 0)
        }
      end
    end
    def vector_count_characters(fields=nil)
      fields=check_fields(fields)
      collect_with_index do |i,row|
        fields.inject(0){|a,v|

          a+((@vectors[v].data_with_nils[i].nil?) ? 0: row[v].to_s.size)
        }
      end
    end
    # Returns a vector with the mean for a set of fields
    # if fields parameter is empty, return the mean for all fields
    # if max invalid parameter > 0, returns the mean for all tuples
    # with 0 to max_invalid invalid fields
    def vector_mean(fields=nil,max_invalid=0)
      a=[]
      fields=check_fields(fields)
      size=fields.size
      each_with_index do |i, row|
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
      a.to_vector(:scale)
    end
    def check_length
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
    def each_vector
      @fields.each{|k| yield k,@vectors[k]}
    end
    if Statsample::STATSAMPLE__.respond_to?(:case_as_hash)
      def case_as_hash(c) # :nodoc:
        Statsample::STATSAMPLE__.case_as_hash(self,c)
      end
    else
      def case_as_hash(c)
        _case_as_hash(c)
      end
    end

    if Statsample::STATSAMPLE__.respond_to?(:case_as_array)
      def case_as_array(c) # :nodoc:
        Statsample::STATSAMPLE__.case_as_array(self,c)
      end
    else
      def case_as_array(c)
        _case_as_array(c)
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
        raise DatasetException.new(self,e)
      end
    end
    # Returns each case as index and hash
    def each_with_index
      begin
        @i=0
        @cases.times{|i|
          @i=i
          row=case_as_hash(i)
          yield i,row
        }
        @i=nil
      rescue =>e
        raise DatasetException.new(self,e)
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
    def fields=(f)
      @fields=f
      check_order
    end
    def check_order
      if(@vectors.keys.sort!=@fields.sort)
        @fields=@fields&@vectors.keys
        @fields+=@vectors.keys.sort-@fields
      end
    end
    # Returns the vector named i
    def[](i)
      if i.is_a? String
        raise Exception,"Vector '#{i}' doesn't exists on dataset" unless @vectors.has_key?(i)
        @vectors[i]
      elsif i.is_a? Range
        fields=from_to(i.begin,i.end)
        vectors=fields.inject({}) {|a,v| a[v]=@vectors[v];a}
        ds=Dataset.new(vectors,fields)
      else
        raise ArgumentError, "You need a String or a Range"
      end
    end
    def collect(type=:scale)
      data=[]
      each {|row|
        data.push(yield(row))
      }
      Statsample::Vector.new(data,type)
    end
    def collect_with_index(type=:scale)
      data=[]
      each_with_index {|i,row|
        data.push(yield(i,row))
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
    def crosstab(v1,v2)
      Statsample::Crosstab.new(@vectors[v1],@vectors[v2])
    end
    def[]=(i,v)
      if v.instance_of? Statsample::Vector
        @vectors[i]=v
        check_order
      else
        raise ArgumentError,"Should pass a Statsample::Vector"
      end
    end
    def to_matrix
      rows=[]
      self.each_array{|c|
        rows.push(c)
      }
      Matrix.rows(rows)
    end
		def to_multiset_by_split(*fields)
			require 'statsample/multiset'
			if fields.size==1
				to_multiset_by_split_one_field(fields[0])
			else
				to_multiset_by_split_multiple_fields(*fields)
			end
		end
    # create a new dataset with all the data which the block returns true
    def filter
      ds=self.dup_empty
      each {|c|
        ds.add_case(c,false) if yield c
      }
      ds.update_valid_data
      ds
    end
		# creates a new vector with the data of a given field which the block returns true
		def filter_field(field)
			a=[]
			each {|c|
				a.push(c[field]) if yield c
			}
			a.to_vector(@vectors[field].type)
		end
    def to_multiset_by_split_one_field(field)
      raise ArgumentError,"Should use a correct field name" if !@fields.include? field
      factors=@vectors[field].factors
      ms=Multiset.new_empty_vectors(@fields,factors)
      each {|c|
        ms[c[field]].add_case(c,false)
      }
      #puts "Ingreso a los dataset"
      ms.datasets.each {|k,ds|
        ds.update_valid_data
        ds.vectors.each{|k1,v1|
          #        puts "Vector #{k1}:"+v1.to_s
          v1.type=@vectors[k1].type
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
        ds.vectors.each{|k1,v1| v1.type=@vectors[k1].type }
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
      collect_with_index {|i,row|
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
      "#<"+self.class.to_s+":"+self.object_id.to_s+" @fields=["+@fields.join(",")+"] labels="+@labels.inspect+" cases="+@vectors[@fields[0]].size.to_s
    end
    def inspect
      self.to_s
    end
		def summary
			out=""
			out << "Summary for dataset\n"
			@vectors.each{|k,v|
				out << "###############\n"
				out << "Vector #{k}:\n"
				out << v.summary
				out << "###############\n"
				
			}
			out 
		end
    def as_r
      require 'rsruby/dataframe'
      r=RSRuby.instance

    end
  end
end
