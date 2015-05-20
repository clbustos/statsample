# Opening the Daru::DataFrame class for adding methods to convert from 
# data structures to specialized statsample data structues like Multiset.
module Daru
  class DataFrame
    # Functions for converting to Statsample::Multiset
    def to_multiset_by_split(*vecs)
      require 'statsample/multiset'

      if vecs.size == 1
        to_multiset_by_split_one_field(vecs[0])
      else
        to_multiset_by_split_multiple_fields(*vecs)
      end
    end
    # Creates a Statsample::Multiset, using one field

    def to_multiset_by_split_one_field(field)
      raise ArgumentError,"Should use a correct field name" if 
        !@vectors.include? field

      factors = self[field].factors
      ms      = Statsample::Multiset.new_empty_vectors(@vectors.to_a, factors)
      each_row do |row|
        ms[row[field]].add_row(row)
      end
      #puts "Ingreso a los dataset"
      ms.datasets.each do |k,ds|
        ds.update
        # puts "idx #{self[field].index_of(k)}"
        ds.rename self[field].index_of(k)
        # ds.vectors.each do |k1,v1|
        #   v1.type   = self[k1].type
        #   v1.name   = self[k1].name
        #   v1.labels = self[k1].to_hash
        # end
      end

      ms
    end

    def to_multiset_by_split_multiple_fields(*fields)
      fields.map!(&:to_sym)
      factors_total=nil
      fields.each do |f|
        if factors_total.nil?
          factors_total = self[f].factors.collect { |c| [c] }
        else
          suma = []
          factors = self[f].factors
          factors_total.each do |f1| 
            factors.each do |f2| 
              suma.push(f1+[f2])
            end
          end
          factors_total = suma
        end
      end
      ms = Statsample::Multiset.new_empty_vectors(vectors.to_a, factors_total)

      p1 = eval "Proc.new {|c| ms[["+fields.collect{|f| "c['#{f}'.to_sym]"}.join(",")+"]].add_row(c) }"
      each_row { |r| p1.call(r) }

      ms.datasets.each do |k,ds|
        ds.update 
        ds.rename(
          fields.size.times.map do |i|
            f  = fields[i]
            sk = k[i]
            self[f].index_of(sk)
          end.join("-")
        )

        # ds.vectors.each do |k1,v1|
        #   v1.type   = ds[k1].type
        #   v1.name   = ds[k1].name
        #   v1.labels = ds[k1].to_hash
        # end
      end
      ms
    end
  end
end