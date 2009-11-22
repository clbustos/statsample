require 'yaml'

module Statsample
# This module aids to code open questions
# * Select one or more vectors of a dataset, to create a yaml files, on which each vector is a hash, which keys and values are the vector's factors . If data have Statsample::SPLIT_TOKEN on a value, each value will be separated on two or more hash keys. 
# * Edit the yaml and replace the values of hashes with your codes. If you need to create two or mores codes for an answer, use the separator (default Statsample::SPLIT_TOKEN)
# * Recode the vectors, loading the yaml file:
#   * recode_dataset_simple!() : The new vectors have the same name of the original plus "_recoded"
#   * recode_dataset_split!() : Create equal number of vectors as values. See Vector.add_vectors_by_split() for arguments
#
# Usage:
#   recode_file="recodification.yaml"
#   phase=:first # flag
#   if phase==:first
#     File.open(recode_file,"w") {|fp|
#       Statsample::Codification.create_yaml(ds,%w{vector1 vector2}, ",",fp)
#     } 
#   # Edit the file recodification.yaml and verify changes
#   elsif phase==:second 
#     File.open(recode_file,"r") {|fp|
#       Statsample::Codification.verify(fp,['vector1'])
#     }
#   # Add new vectors to the dataset
#   elsif phase==:third
#     File.open(recode_file,"r") {|fp|
#       Statsample::Codification.recode_dataset_split!(ds,fp,"*")
#     }
#   end
#     
    module Codification
        class << self
            # Create a yaml dump for a hash, based on vectors
            # The keys will be vectors name on dataset and the values
            # will be hashes, with keys = values, for recodification
            # 
            #   v1=%w{a,b b,c d}.to_vector
            #   ds={"v1"=>v1}.to_dataset
            #   Statsample::Codification.create_yaml(ds,['v1'])
            #   => "--- \nv1: \n  a: a\n  b: b\n  c: c\n  d: d\n"
            def create_yaml(dataset,vectors,sep=Statsample::SPLIT_TOKEN,io=nil)
                raise ArgumentError,"Array should't be empty" if vectors.size==0
                pro_hash=vectors.inject({}){|h,v_name|
                    raise Exception, "Vector #{v_name} doesn't exists on Dataset" if !dataset.fields.include? v_name
                    v=dataset[v_name]
                    split_data=v.splitted(sep)
                    factors=split_data.flatten.uniq.compact.sort.inject({}) {|ac,val| ac[val]=val;ac}
                    h[v_name]=factors
                    h
                }
                YAML.dump(pro_hash,io)
            end
            def inverse_hash(h,sep=Statsample::SPLIT_TOKEN)
                h.inject({}) {|a,v|
                    v[1].split(sep).each {|val|
                        a[val]||=[]
                        a[val].push(v[0])
                    }
                    a
                }
            end
            def dictionary(h,sep=Statsample::SPLIT_TOKEN)
                h.inject({}) {|a,v|
                    a[v[0]]=v[1].split(sep)
                    a
                }
            end
            def recode_vector(v,h,sep=Statsample::SPLIT_TOKEN)
                dict=dictionary(h,sep)
                new_data=v.splitted(sep)
                recoded=new_data.collect{|c|
                    if c.nil?
                        nil
                    else
                    c.collect{|value|
                        dict[value]
                    }.flatten.uniq
                end
                }
            end
            def recode_dataset_simple!(dataset,yaml,sep=Statsample::SPLIT_TOKEN)
                _recode_dataset(dataset,yaml,sep,false)
            end
            def recode_dataset_split!(dataset,yaml,sep=Statsample::SPLIT_TOKEN)
                _recode_dataset(dataset,yaml,sep,true)
            end
            
            def _recode_dataset(dataset,yaml,sep=Statsample::SPLIT_TOKEN,split=false)
                h=YAML::load(yaml)
                v_names||=h.keys
                v_names.each do |v_name|
                    raise Exception, "Vector #{v_name} doesn't exists on Dataset" if !dataset.fields.include? v_name
                    recoded=recode_vector(dataset[v_name],h[v_name],sep).collect { |c|
                        if c.nil?
                            nil
                        else
                            c.join(sep)
                        end
                    }.to_vector
                    if(split)
                    recoded.split_by_separator(sep).each {|k,v|
                        dataset[v_name+"_"+k]=v
                    }
                    else
                        dataset[v_name+"_recoded"]=recoded
                    end
                end
            end
            def verify(yaml,v_names=nil,sep=Statsample::SPLIT_TOKEN,io=$>)
                require 'pp'
                h=YAML::load(yaml)
                v_names||=h.keys
                v_names.each{|v_name|
                    inverse=inverse_hash(h[v_name],sep)
                    io.puts "Vector: #{v_name}"
                    YAML.dump(inverse.sort,io)
                }
            end
        end
    end
end
