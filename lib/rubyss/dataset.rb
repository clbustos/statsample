require 'rubyss/vector'
require 'gnuplot'

class Hash
	def to_dataset(*args)
		RubySS::Dataset.new(self,*args)
	end
end


module RubySS
    class Dataset
        attr_reader :vectors, :fields, :cases
        attr_accessor :labels
        # To create a dataset
        # * Dataset.new()
        # * Dataset.new(%w{v1 v2 v3})
        # * Dataset.new({'v1'=>%w{1 2 3}.to_vector, 'v2'=>%w{4 5 6}.to_vector})
        # * Dataset.new({'v2'=>v2,'v1'=>v1},['v1','v2'])
        #
        def initialize(vectors={},fields=[],labels={})
            if vectors.instance_of? Array
                @fields=vectors.dup
                @vectors=vectors.inject({}){|a,x| a[x]=RubySS::Vector.new(); a}
            else
                @vectors=vectors
                @fields=fields
                check_order
                check_length
            end
            @labels=labels
        end
        # Creates a copy of the given dataset, deleting all the cases with
        # missing data on one of the vectors
        def dup_only_valid
            ds=dup_empty
            each {|c|
                ds.add_case(c,false) unless @fields.find{|f| !@vectors[f].is_valid? c[f]}
            }
            ds.update_valid_data
            ds
        end
        # Returns a duplicate of the Database
        def dup
            vectors=@vectors.inject({}) {|a,v|
                a[v[0]]=v[1].dup
                a
            }
            Dataset.new(vectors,@fields.dup,@labels.dup)
        end
        # Creates a copy of the given dataset, without data on vectors
        def dup_empty
            vectors=@vectors.inject({}) {|a,v|
                a[v[0]]=v[1].dup_empty
                a
            }
            Dataset.new(vectors,@fields.dup,@labels.dup)
        end
        # We have the same datasets if the labels and vectors are the same 
        def ==(d2)
            @vectors==d2.vectors and @fields==d2.fields
        end
        def self.load(filename)
            fp=File.open(filename,"r")
            o=Marshal.load(fp)
            fp.close
            o
        end
        def save(filename)
            fp=File.open(filename,"w")
            Marshal.dump(self,fp)
            fp.close
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
        def add_case(v,uvd=true)
            case v
            when Array
                if (v[0].is_a? Array)
                    v.each{|subv| add_case(subv,false)}
                else
                    raise ArgumentError, "Array size should be equal to fields number" if @fields.size!=v.size
                    (0...v.size).each{|i| @vectors[@fields[i]].add(v[i],false)}
                end
            when Hash
                raise ArgumentError, "Hash keys should be equal to fields" if @fields.sort!=v.keys.sort
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
        def add_vectors_by_split_recode(name,join='-',sep=",")
            split=@vectors[name].split_by_separator(sep)
            i=1
            split.each{|k,v|
                new_field=name+join+i.to_s
                @labels[new_field]=name+":"+k
                add_vector(new_field,v)
                i+=1
            }
        end
        def add_vectors_by_split(name,join='-',sep=",")
            split=@vectors[name].split_by_separator(sep)
            split.each{|k,v|
                add_vector(name+join+k,v)
            }
        end        
        def check_length
            size=nil
            @vectors.each{|k,v|
                raise Exception, "Data #{v.class} is not a vector on key #{k}" if !v.is_a? RubySS::Vector
                if size.nil?
                    size=v.size
                else
                    if v.size!=size
                        p v.to_a.size
                        raise Exception, "Vector #{k} have size #{v.size} and dataset have size #{size}"
                    end
                end
            }
            @cases=size
            end
            def each_vector
                @vectors.each{|k,v|
                    yield k,v
                }
            end
        if !RubySS::OPTIMIZED
            def case_as_hash(c)
                @fields.inject({}) {|a,x|
                        a[x]=@vectors[x][c]
                        a
            }
            end
            def case_as_array(c)
                @fields.collect {|x| @vectors[x][c]}
            end            
        end
        def each
            0.upto(@cases-1) {|i|
                row=case_as_hash(i)
                yield row
            }
        end
        def each_array
            0.upto(@cases-1) {|i|
                row=case_as_array(i)
                yield row
            }
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
        def[](i)
            @vectors[i]
        end
        def[]=(i,v)
            if v.instance_of? RubySS::Vector
                @vectors[i]=v
                check_order
            else
                raise ArgumentError,"Should pass a RubySS::Vector"
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
			require 'rubyss/multiset'
			if fields.size==1
				to_multiset_by_split_one_field(fields[0])
			else
				to_multiset_by_split_multiple_fields(*fields)
			end
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
			fields.each{|f|
				if factors_total.nil?
					factors_total=@vectors[f].factors.collect{|c|
						[c]
					}
				else
					suma=[]
					factors=@vectors[f].factors
					factors_total.each{|f1|
						factors.each{|f2|
							suma.push(f1+[f2])
						}
					}
					factors_total=suma
				end
			}
			ms=Multiset.new_empty_vectors(@fields,factors_total)
			p1=eval "Proc.new {|c| ms[["+fields.collect{|f| "c['#{f}']"}.join(",")+"]].add_case(c,false) }"
			each{|c|
				p1.call(c)
			}
            ms.datasets.each {|k,ds|
                ds.update_valid_data
                ds.vectors.each{|k1,v1|
                #   puts "Vector #{k1}:"+v1.to_s
                    v1.type=@vectors[k1].type
                }
            }
            ms
			
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
    end
end
