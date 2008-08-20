require 'rubyss/vector'
module RubySS
    class Dataset
        attr_reader :vectors,:fields, :cases
        def initialize(vectors,fields=false)
            @vectors=vectors
            @fields=fields if fields
            check_order
            check_length
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
        def delete_vector(name)
            @fields.delete(name)
            @vectors.delete(name)
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
                if size.nil?
                    size=v.size
                else
                    raise Exception, "Vector #{k} have different size" if v.size!=size
                end
            }
            @cases=size
        end
        def case_as_hash(c)
            @fields.inject({}) {|a,x|
                    a[x]=@vectors[x][c]
                    a
        }
        end
        def case_as_array(c)
            @fields.collect {|x| @vectors[x][c]}
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
        def check_order
            if(@vectors.keys.sort!=@fields.sort)
                @fields=@fields&@vectors.keys
                @fields+=@vectors.keys-@fields
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
    end
    class CSV
        require 'csv'
        # Returns a Dataset  based on a csv file
        #
        # USE:
        #     ds=RubySS::CSV.read("test_csv.csv")
        def self.read(filename)
                first_row=true
                fields=[]
                fields_data={}
                ::CSV.open(filename,'r') do |row|
                    if first_row
                        fields=row
                        fields_data=fields.inject({}) {|a,x|
                            a[x]=[]
                            a
                        }
                        first_row=false
                    else
                        0.upto(fields.size-1) {|x|
                            fields_data[fields[x]].push(row[x])
                        }
                    end
                end
                fd=fields_data.inject({}) {|a,x|
                    a[x[0]]=Vector.new(x[1],:nominal)
                    a
                }
                Dataset.new(fd,fields)
            end
            def self.write(dataset,filename)
                writer=::CSV.open(filename,'w')
                writer << dataset.fields
                dataset.each_array{|row|
                    writer << row
                }
                writer.close
            end
    end
end
