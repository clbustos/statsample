module Statsample
  class Vector
    module GSL_      
      def clear_gsl
        @gsl=nil
      end
      
      def set_scale_data
        set_scale_data_ruby
        clear_gsl
      end
      def push_(v)
        # If data is GSL::Vector, should be converted first to an Array
        if @data.is_a? GSL::Vector
          @data=@data.to_a
        end
        push_ruby(v)
      end
      
      def gsl
        @gsl||=GSL::Vector.alloc(@scale_data) if @scale_data.size>0
      end
      
      alias :to_gsl :gsl
      def vector_standarized_compute_(m,sd)
        if flawed?
          vector_standarized_compute_ruby(m,sd)
        else
          gsl.collect {|x| (x.to_f - m).quo(sd)}.to_scale
        end
      end
      
      def vector_centered_compute_(m)
        if flawed?
          vector_centered_compute_ruby(m)
        else
          gsl.collect {|x| (x.to_f - m)}.to_scale
        end
      end
      def sample_with_replacement(sample=1)
        if(@type!=:scale)
          sample_with_replacement_ruby(sample)
        else
          r = GSL::Rng.alloc(GSL::Rng::MT19937,rand(10000))
          Statsample::Vector.new(r.sample(gsl, sample).to_a,:scale)
        end
      end
      
      def sample_without_replacement(sample=1)
        if(@type!=:scale)
          sample_without_replacement_ruby(sample)
        else
          r = GSL::Rng.alloc(GSL::Rng::MT19937,rand(10000))
          r.choose(gsl, sample).to_a
        end
      end
      def median
        if @type!=:scale
          median_ruby
        else
          sorted=GSL::Vector.alloc(@scale_data.sort)
          GSL::Stats::median_from_sorted_data(sorted)
        end
      end
      
      def sum 
        check_type :scale
        gsl.nil? ? nil : gsl.sum
      end
      def mean
        check_type :scale
        gsl.nil? ? nil : gsl.mean
      end				
      def variance_sample(m=nil)
        check_type :scale
        m||=mean
        gsl.nil? ? nil : gsl.variance_m
      end
      
      def standard_deviation_sample(m=nil)
        check_type :scale
        m||=mean
        gsl.nil? ? nil : gsl.sd(m)
      end

      def variance_population(m=nil) # :nodoc:
        check_type :scale    
        m||=mean
        gsl.nil? ? nil : gsl.variance_with_fixed_mean(m)
      end
      def standard_deviation_population(m=nil) # :nodoc:
        check_type :scale
        m||=mean
        gsl.nil? ? nil : gsl.sd_with_fixed_mean(m)
      end
      def skew # :nodoc:
        check_type :scale
        gsl.nil? ? nil : gsl.skew
      end
      def kurtosis # :nodoc:
        check_type :scale
        gsl.nil? ? nil : gsl.kurtosis
      end
    end
  end
end
