module Statsample
  # Multiset joins multiple dataset with the same fields and vectors
  # but with different number of cases. 
  # This is the base class for stratified and cluster sampling estimation
  class Multiset
    # Name of fields
    attr_reader :fields
    # Array with Daru::DataFrame
    attr_reader :datasets
    # To create a multiset
    # * Multiset.new(%w{f1 f2 f3}) # define only fields
    def initialize(fields)
      @fields=fields
      @datasets={}
    end
    def self.new_empty_vectors(fields,ds_names) 
      ms = Multiset.new(fields)
      ds_names.each do |d|
        ms.add_dataset(d, Daru::DataFrame.new({}, order: fields))
      end

      ms
    end
    # Generate a new dataset as a union of partial dataset
    # If block given, this is applied to each dataset before union
    def union(&block)
      union_field={}
      types={}
      names={}
      labels={}
      each do |k,ds|
        if block
          ds = ds.dup
          yield k,ds
        end
        @fields.each do |f|
          union_field[f] ||= Array.new
          union_field[f].concat(ds[f].to_a)
          types[f]  ||= ds[f].type
          names[f]  ||= ds[f].name
          labels[f] ||= ds[f].index.to_a
        end
      end
      
      @fields.each do |f|
        union_field[f] = Daru::Vector.new(union_field[f])
        union_field[f].rename names[f]
      end

      ds_union = Daru::DataFrame.new(union_field, order: @fields)
      ds_union
    end

    def datasets_names
      @datasets.keys.sort
    end

    def n_datasets
      @datasets.size
    end

    def add_dataset(key,ds)
      if ds.vectors.to_a != @fields
        raise ArgumentError, "Dataset(#{ds.vectors.to_a.to_s})must have the same fields of the Multiset(#{@fields})"
      else
        @datasets[key] = ds
      end
    end
    def sum_field(field)
      @datasets.inject(0) {|a,da|
        stratum_name = da[0]
        vector       = da[1][field]
        val          = yield stratum_name,vector
        a + val
      }
    end
    def collect_vector(field)
      @datasets.collect { |k,v| yield k, v[field] }
    end
    
    def each_vector(field)
      @datasets.each { |k,v| yield k, v[field] }
    end

    def [](i)
      @datasets[i]
    end

    def each(&block)
      @datasets.each {|k,ds|
        next if ds.nrows == 0
        block.call(k,ds)
      }
    end
  end
  class StratifiedSample
    class << self
      # mean for an array of vectors
      def mean(*vectors)
        n_total=0
        means=vectors.inject(0){|a,v|
          n_total+=v.size
          a+v.sum
        }
        means.to_f/n_total
      end
      
      def standard_error_ksd_wr(es)
        n_total=0
        sum=es.inject(0){|a,h|
            n_total+=h['N']
            a+((h['N']**2 * h['s']**2) / h['n'].to_f)
        }
        (1.to_f / n_total)*Math::sqrt(sum)
      end
      
      
      def variance_ksd_wr(es)
        standard_error_ksd_wr(es)**2
      end
      def calculate_n_total(es)
        es.inject(0) {|a,h| a+h['N'] }
      end
      # Source : Cochran (1972)
      
      def variance_ksd_wor(es)
      n_total=calculate_n_total(es)
      es.inject(0){|a,h|
        val=((h['N'].to_f / n_total)**2) * (h['s']**2 / h['n'].to_f) * (1 - (h['n'].to_f / h['N']))
        a+val
      }
      end
      def standard_error_ksd_wor(es)
        Math::sqrt(variance_ksd_wor(es))
      end
      
      
      
      def variance_esd_wor(es)
        n_total=calculate_n_total(es)
        sum=es.inject(0){|a,h|
          val=h['N']*(h['N']-h['n'])*(h['s']**2 / h['n'].to_f)
          a+val
        }
        (1.0/(n_total**2))*sum
      end
      
      
      def standard_error_esd_wor(es)
        Math::sqrt(variance_ksd_wor(es))
      end
      # Based on http://stattrek.com/Lesson6/STRAnalysis.aspx
      def variance_esd_wr(es)
        n_total=calculate_n_total(es)
          sum=es.inject(0){|a,h|
            val= ((h['s']**2 * h['N']**2) / h['n'].to_f)
            a+val
          }
          (1.0/(n_total**2))*sum
      end
      def standard_error_esd_wr(es)
        Math::sqrt(variance_esd_wr(es))
      end
      
      def proportion_variance_ksd_wor(es)
        n_total=calculate_n_total(es)
          es.inject(0){|a,h|
            val= (((h['N'].to_f / n_total)**2 * h['p']*(1-h['p'])) / (h['n'])) * (1- (h['n'].to_f / h['N']))
            a+val
          }
      end
      def proportion_sd_ksd_wor(es)
          Math::sqrt(proportion_variance_ksd_wor(es))
      end
      
      
      def proportion_sd_ksd_wr(es)
        n_total=calculate_n_total(es)
        sum=es.inject(0){|a,h|
          val= (h['N']**2 * h['p']*(1-h['p'])) / h['n'].to_f
          a+val
        }
        Math::sqrt(sum) * (1.0/n_total)
      end
      def proportion_variance_ksd_wr(es)
          proportion_variance_ksd_wor(es)**2
      end
      
      def proportion_variance_esd_wor(es)
        n_total=n_total=calculate_n_total(es)
        
        sum=es.inject(0){|a,h|
          a=(h['N']**2 * (h['N']-h['n']) * h['p']*(1.0-h['p'])) / ((h['n']-1)*(h['N']-1))
          a+val
        }
        Math::sqrt(sum) * (1.0/n_total**2)
      end
      def proportion_sd_esd_wor(es)
          Math::sqrt(proportion_variance_ksd_wor(es))
      end
    end
    
    def initialize(ms,strata_sizes)
      raise TypeError,"ms should be a Multiset" unless ms.is_a? Statsample::Multiset
      @ms=ms
      raise ArgumentError,"You should put a strata size for each dataset" if strata_sizes.keys.sort!=ms.datasets_names
      @strata_sizes=strata_sizes
      @population_size=@strata_sizes.inject(0) { |a,x| a+x[1] }
      @strata_number=@ms.n_datasets
      @sample_size=@ms.datasets.inject(0) { |a,x| a+x[1].nrows }
    end
    # Number of strata
    def strata_number
      @strata_number
    end
    # Population size. Equal to sum of strata sizes
    # Symbol: N<sub>h</sub>
    def population_size
      @population_size
    end
    # Sample size. Equal to sum of sample of each stratum
    def sample_size
      @sample_size
    end
    # Size of stratum x
    def stratum_size(h)
      @strata_sizes[h]
    end
    def vectors_by_field(field)
      @ms.datasets.collect{|k,ds|
        ds[field]
      }
    end
    # Population proportion based on strata
    def proportion(field, v=1)
      @ms.sum_field(field) {|s_name,vector|
      stratum_ponderation(s_name)*vector.proportion(v)
      }
    end
    # Stratum ponderation.
    # Symbol: W\<sub>h\</sub>
    def stratum_ponderation(h)
      @strata_sizes[h].to_f / @population_size
    end
    alias_method :wh, :stratum_ponderation
    
    # Population mean based on strata
    def mean(field)
      @ms.sum_field(field) {|s_name,vector|
      stratum_ponderation(s_name)*vector.mean
      }
    end
    # Standard error with estimated population variance and without replacement.
    # Source: Cochran (1972)
    def standard_error_wor(field)
      es=@ms.collect_vector(field) {|s_n, vector|
        {'N'=>@strata_sizes[s_n],'n'=>vector.size, 's'=>vector.sds}
      }
      
      StratifiedSample.standard_error_esd_wor(es)
    end
    
    # Standard error with estimated population variance and without replacement.
    # Source: http://stattrek.com/Lesson6/STRAnalysis.aspx
    
    def standard_error_wor_2(field)
      sum=@ms.sum_field(field) {|s_name,vector|
        s_size=@strata_sizes[s_name]
      (s_size**2 * (1-(vector.size.to_f / s_size)) * vector.variance_sample / vector.size.to_f)
      }
      (1/@population_size.to_f)*Math::sqrt(sum)
    end
    
    def standard_error_wr(field)
      es=@ms.collect_vector(field) {|s_n, vector|
        {'N'=>@strata_sizes[s_n],'n'=>vector.size, 's'=>vector.sds}
      }
      
      StratifiedSample.standard_error_esd_wr(es)
    end
    def proportion_sd_esd_wor(field,v=1)
      es=@ms.collect_vector(field) {|s_n, vector|
        {'N'=>@strata_sizes[s_n],'n'=>vector.size, 'p'=>vector.proportion(v)}
      }
      
      StratifiedSample.proportion_sd_esd_wor(es)
    end
    
    def proportion_standard_error(field,v=1)
      prop=proportion(field,v)
      sum=@ms.sum_field(field) {|s_name,vector|
        nh=vector.size
        s_size=@strata_sizes[s_name]
        (s_size**2 * (1-(nh / s_size)) * prop * (1-prop) / (nh - 1 ))
      }
      (1.quo(@population_size)) * Math::sqrt(sum)
    end
    # Cochran(1971), p. 150 
    def variance_pst(field,v=1)
      sum=@ms.datasets.inject(0) {|a,da|
        stratum_name=da[0]
        ds=da[1]
        nh=ds.cases.to_f
        s_size=@strata_sizes[stratum_name]
        prop=ds[field].proportion(v)
        a + (((s_size**2 * (s_size-nh)) / (s_size-1))*(prop*(1-prop) / (nh-1)))
      }
      (1/@population_size.to_f ** 2)*sum
    end
  end
end
