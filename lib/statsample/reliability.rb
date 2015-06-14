module Statsample
  module Reliability
    class << self
      # Calculate Chonbach's alpha for a given dataset.
      # only uses tuples without missing data
      def cronbach_alpha(ods)
        ds = ods.dup_only_valid
        n_items = ds.ncols
        return nil if n_items <= 1
        s2_items = ds.to_hash.values.inject(0) { |ac,v| 
          ac + v.variance }
        total    = ds.vector_sum
        
        (n_items.quo(n_items - 1)) * (1 - (s2_items.quo(total.variance)))
      end
      # Calculate Chonbach's alpha for a given dataset
      # using standarized values for every vector.
      # Only uses tuples without missing data
      # Return nil if one or more vectors has 0 variance
      def cronbach_alpha_standarized(ods)
        ds = ods.dup_only_valid
        return nil if ds.any? { |v| v.variance==0}
        
        ds = Daru::DataFrame.new(
          ds.vectors.to_a.inject({}) { |a,i|
            a[i] = ods[i].standardize
            a
          }
        )
                
        cronbach_alpha(ds)
      end
      # Predicted reliability of a test by replicating
      # +n+ times the number of items 
      def spearman_brown_prophecy(r,n)
        (n*r).quo(1+(n-1)*r)
      end
      
      alias :sbp :spearman_brown_prophecy
      # Returns the number of items 
      # to obtain +r_d+ desired reliability
      # from +r+ current reliability, achieved with
      # +n+ items
      def n_for_desired_reliability(r,r_d,n=1)
        return nil if r.nil?
        (r_d*(1-r)).quo(r*(1-r_d))*n
      end
      
      # Get Cronbach alpha from <tt>n</tt> cases, 
      # <tt>s2</tt> mean variance and <tt>cov</tt>
      # mean covariance
      def cronbach_alpha_from_n_s2_cov(n,s2,cov)
        (n.quo(n-1)) * (1-(s2.quo(s2+(n-1)*cov)))
      end
      # Get Cronbach's alpha from a covariance matrix
      def cronbach_alpha_from_covariance_matrix(cov)
        n = cov.row_size
        raise "covariance matrix should have at least 2 variables" if n < 2
        s2 = n.times.inject(0) { |ac,i| ac + cov[i,i] }
        (n.quo(n - 1)) * (1 - (s2.quo(cov.total_sum)))
      end
      # Returns n necessary to obtain specific alpha
      # given variance and covariance mean of items
      def n_for_desired_alpha(alpha,s2,cov)
        # Start with a regular test : 50 items
        min=2
        max=1000
        n=50
        prev_n=0
        epsilon=0.0001
        dif=1000
        c_a=cronbach_alpha_from_n_s2_cov(n,s2,cov)
        dif=c_a - alpha
        while(dif.abs>epsilon and n!=prev_n)
          prev_n=n
          if dif<0
            min=n
            n=(n+(max-min).quo(2)).to_i
          else
            max=n
            n=(n-(max-min).quo(2)).to_i
          end
          c_a=cronbach_alpha_from_n_s2_cov(n,s2,cov)
          dif=c_a - alpha
        end
        n
      end
      # First derivative for alfa
      # Parameters
      # <tt>n</tt>: Number of items
      # <tt>sx</tt>: mean of variances 
      # <tt>sxy</tt>: mean of covariances
      
      def alpha_first_derivative(n,sx,sxy)
        (sxy*(sx-sxy)).quo(((sxy*(n-1))+sx)**2)
      end
      # Second derivative for alfa
      # Parameters
      # <tt>n</tt>: Number of items
      # <tt>sx</tt>: mean of variances 
      # <tt>sxy</tt>: mean of covariances
      
      def alfa_second_derivative(n,sx,sxy)
        (2*(sxy**2)*(sxy-sx)).quo(((sxy*(n-1))+sx)**3)
      end
    end
    class ItemCharacteristicCurve
      attr_reader :totals, :counts, :vector_total
      def initialize (ds, vector_total=nil)
        vector_total||=ds.vector_sum
        raise ArgumentError, "Total size != Dataset size" if vector_total.size != ds.nrows
        @vector_total=vector_total
        @ds=ds
        @totals={}
        @counts=@ds.vectors.to_a.inject({}) {|a,v| a[v]={};a}
        process
      end
      def process
        i=0
        @ds.each_row do |row|
          tot=@vector_total[i]
          @totals[tot]||=0
          @totals[tot]+=1
          @ds.vectors.each  do |f|
            item=row[f].to_s
            @counts[f][tot]||={}
            @counts[f][tot][item]||=0
            @counts[f][tot][item] += 1
          end
          i+=1
        end
      end
      # Return a hash with p for each different value on a vector
      def curve_field(field, item)
        out={}
        item=item.to_s
        @totals.each do |value,n|
          count_value= @counts[field][value][item].nil? ? 0 : @counts[field][value][item]
          out[value]=count_value.quo(n)
        end
        out
      end # def
    end # self
  end # Reliability
end # Statsample

require 'statsample/reliability/icc.rb'
require 'statsample/reliability/scaleanalysis.rb'
require 'statsample/reliability/skillscaleanalysis.rb'
require 'statsample/reliability/multiscaleanalysis.rb'
