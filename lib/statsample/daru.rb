# Opening the Daru::DataFrame class for adding methods to convert from 
# data structures to specialized statsample data structues like Multiset.
module Daru
  class Vector
    def histogram(bins=10)
      type == :numeric or raise TypeError, "Only numeric Vectors can do this operation."

      if bins.is_a? Array
        h = Statsample::Histogram.alloc(bins)
      else
        # ugly patch. The upper limit for a bin has the form
        # x < range
        #h=Statsample::Histogram.new(self, bins)
        valid = only_valid
        min,max=Statsample::Util.nice(valid.min,valid.max)
        # fix last data
        if max == valid.max
          max += 1e-10
        end
        h = Statsample::Histogram.alloc(bins,[min,max])
        # Fix last bin
      end

      h.increment(valid)
      h
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
  end

  class DataFrame
    def crosstab(v1,v2,opts={})
      Statsample::Crosstab.new(self[v1], self[v2],opts)
    end

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
        ds.rename self[field].index_of(k)
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
      end
      ms
    end
  end
end