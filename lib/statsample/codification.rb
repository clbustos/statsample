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
      # Create a hash, based on vectors, to create the dictionary.
      # The keys will be vectors name on dataset and the values
      # will be hashes, with keys = values, for recodification
      def create_hash(dataset, vectors, sep=Statsample::SPLIT_TOKEN)
        raise ArgumentError,"Array should't be empty" if vectors.size==0
        pro_hash = vectors.inject({}) do |h,v_name|
          v_name = v_name.is_a?(Numeric) ? v_name : v_name.to_sym
          raise Exception, "Vector #{v_name} doesn't exists on Dataset" if 
            !dataset.vectors.include?(v_name)
          v = dataset[v_name]
          split_data = v.splitted(sep)
                        .flatten
                        .collect { |c| c.to_s  }
                        .find_all{ |c| !c.nil? }

          factors   = split_data.uniq
                                .compact
                                .sort
                                .inject({}) { |ac,val| ac[val] = val; ac }
          h[v_name] = factors
          h
        end

        pro_hash
      end
      # Create a yaml to create a dictionary, based on vectors
      # The keys will be vectors name on dataset and the values
      # will be hashes, with keys = values, for recodification
      #
      #   v1 = Daru::Vector.new(%w{a,b b,c d})
      #   ds = Daru::DataFrame.new({:v1 => v1})
      #   Statsample::Codification.create_yaml(ds,[:v1])
      #   => "--- \nv1: \n  a: a\n  b: b\n  c: c\n  d: d\n"
      def create_yaml(dataset, vectors, io=nil, sep=Statsample::SPLIT_TOKEN)
        pro_hash=create_hash(dataset, vectors, sep)
        YAML.dump(pro_hash,io)
      end
      # Create a excel to create a dictionary, based on vectors.
      # Raises an error if filename exists
      # The rows will be:
      # * field: name of vector
      # * original: original name
      # * recoded: new code

      def create_excel(dataset, vectors, filename, sep=Statsample::SPLIT_TOKEN)
        require 'spreadsheet'
        if File.exist?(filename)
          raise "Exists a file named #{filename}. Delete ir before overwrite."
        end
        book  = Spreadsheet::Workbook.new
        sheet = book.create_worksheet
        sheet.row(0).concat(%w(field original recoded))
        i = 1
        create_hash(dataset, vectors, sep).sort.each do |field, inner_hash|
          inner_hash.sort.each do |k,v|
            sheet.row(i).concat([field.to_s,k.to_s,v.to_s])
            i += 1
          end
        end

        book.write(filename)
      end
      # From a excel generates a dictionary hash
      # to use on recode_dataset_simple!() or recode_dataset_split!().
      #
      def excel_to_recoded_hash(filename)
        require 'spreadsheet'
        h={}
        book = Spreadsheet.open filename
        sheet= book.worksheet 0
        row_i=0
        sheet.each do |row|
          row_i += 1
          next if row_i == 1 or row[0].nil? or row[1].nil? or row[2].nil?
          key = row[0].to_sym
          h[key] ||= {}
          h[key][row[1]] = row[2]
        end
        h
      end

      def inverse_hash(h, sep=Statsample::SPLIT_TOKEN)
        h.inject({}) do |a,v|
          v[1].split(sep).each do |val|
            a[val]||=[]
            a[val].push(v[0])
          end
          a
        end
      end

      def dictionary(h, sep=Statsample::SPLIT_TOKEN)
        h.inject({}) { |a,v| a[v[0]]=v[1].split(sep); a }
      end

      def recode_vector(v,h,sep=Statsample::SPLIT_TOKEN)
        dict     = dictionary(h,sep)
        new_data = v.splitted(sep)
        new_data.collect do |c|
          if c.nil?
            nil
          else
            c.collect{|value| dict[value] }.flatten.uniq
          end
        end
      end
      def recode_dataset_simple!(dataset, dictionary_hash ,sep=Statsample::SPLIT_TOKEN)
        _recode_dataset(dataset,dictionary_hash ,sep,false)
      end
      def recode_dataset_split!(dataset, dictionary_hash, sep=Statsample::SPLIT_TOKEN)
        _recode_dataset(dataset, dictionary_hash, sep,true)
      end

      def _recode_dataset(dataset, h , sep=Statsample::SPLIT_TOKEN, split=false)
        v_names||=h.keys
        v_names.each do |v_name|
          raise Exception, "Vector #{v_name} doesn't exists on Dataset" if !dataset.vectors.include? v_name
          recoded = Daru::Vector.new(
            recode_vector(dataset[v_name], h[v_name],sep).collect do |c|
              if c.nil?
                nil
              else
                c.join(sep)
              end
            end
          )
          if split
            recoded.split_by_separator(sep).each {|k,v|
              dataset[(v_name.to_s + "_" + k).to_sym] = v
            }
          else
            dataset[(v_name.to_s + "_recoded").to_sym] = recoded
          end
        end
      end


      def verify(h, v_names=nil,sep=Statsample::SPLIT_TOKEN,io=$>)
        require 'pp'
        v_names||=h.keys
        v_names.each{|v_name|
          inverse=inverse_hash(h[v_name],sep)
          io.puts "- Field: #{v_name}"
          inverse.sort{|a,b| -(a[1].count<=>b[1].count)}.each {|k,v|
            io.puts "  - \"#{k}\" (#{v.count}) :\n    -'"+v.join("\n    -'")+"'"
          }
        }
      end
    end
  end
end
