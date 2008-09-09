require 'rubyss/dataset'
module RubySS
    # Multiset joins multiple dataset with the same fields and vectors
    # but with different number of cases. 
    # This is the base class for stratified and cluster sampling estimation
    class Multiset
        attr_reader :fields, :datasets
        # To create a multiset
        # * Multiset.new(%w{f1 f2 f3}) # define only fields
        def initialize(fields)
            @fields=fields
            @datasets={}
        end
        def self.new_empty_vectors(fields,ds_names) 
            ms=Multiset.new(fields)
            ds_names.each{|d|
                ms.add_dataset(d,Dataset.new(fields))
            }
            ms
        end
        def datasets_names
            @datasets.keys.sort
        end
        def n_datasets
            @datasets.size
        end
        def add_dataset(key,ds)
            if(ds.fields!=@fields)
            raise ArgumentError, "Dataset(#{ds.fields.to_s})must have the same fields of the Multiset(#{@fields})"
            else
                @datasets[key]=ds
            end
        end
        def[](i)
            @datasets[i]
        end
    end
    class StratifiedSample
        def initialize(ms,strata_sizes)
            raise TypeError,"ms should be a Multiset" unless ms.is_a? RubySS::Multiset
            @ms=ms
            raise ArgumentError,"You should put a strata size for each dataset" if strata_sizes.keys.sort!=ms.datasets_names
            @strata_sizes=strata_sizes
            @population_size=@strata_sizes.inject(0) {|a,x| a+x[1]}
            @strata_number=@ms.n_datasets
            @sample_size=@ms.datasets.inject(0) {|a,x| a+x[1].cases}
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
        # Population proportion based on strata
        def proportion(field, v=1)
            @ms.datasets.inject(0){|a,da|
                s_name=da[0]
                d=da[1]
                a+(stratum_ponderation(s_name)*d[field].proportion(v))
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
            @ms.datasets.inject(0){|a,da|
                d=da[1]
                a+(stratum_ponderation(da[0])*d[field].mean)
            }
        end
        # Standard error with estimated population variance and without replacement.
        # Source: http://stattrek.com/Lesson6/STRAnalysis.aspx
        def standard_error(field)
            sum=@ms.datasets.inject(0) {|a,da|
                dn=da[0]
                s_size=@strata_sizes[dn]
                d=da[1]
                a+ (s_size**2 * (1-(d.cases.to_f/s_size)) * d[field].variance_sample / d.cases.to_f)
            }
            (1/@population_size.to_f)*Math::sqrt(sum)
        end
        
        def proportion_standard_error(field,v=1)
            sum=@ms.datasets.inject(0) {|a,da|
                stratum_name=da[0]
                ds=da[1]
                nh=ds.cases.to_f
                s_size=@strata_sizes[stratum_name]
                prop=proportion(field,v)
                a+ (s_size**2 * (1-(nh/s_size)) * prop * (1-prop) / (nh -1 ))
            }
            (1/@population_size.to_f)*Math::sqrt(sum)
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
