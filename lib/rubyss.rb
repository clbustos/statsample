# = rubyss.rb - 

# Process files and databases for statistical purposes, with focus on 
# estimation of parameters for several types of samples (simple random, 
# stratified and multistage sampling).
#
# Copyright (C) 2008 Claudio Bustos
#
# Claudio Bustos mailto:clbustos@gmail.com

$:.unshift(File.dirname(__FILE__))
$:.unshift(File.expand_path(File.dirname(__FILE__)+"/../ext"))

require 'delegate'
require 'matrix'


class Numeric
  def square ; self * self ; end
end

# Process files and databases for statistical purposes, with focus on 
# estimation of parameters for several types of samples (simple random, 
# stratified and multistage sampling).

	begin
		require 'rbgsl'
		HAS_GSL=true
	rescue LoadError
		HAS_GSL=false
	end
    
    begin 
       require 'rubyss/rubyssopt'
    rescue LoadError
        module RubySS
            OPTIMIZED=false
        end
    end
require 'rubyss/vector'
	
module RubySS
	VERSION = '0.1.6'
    class << self
        def continuity_correction(n_sample,n_poblation)
            ((n_poblation - n_sample) / ( n_poblation - 1))
        end
        # Varianza de p para poblacion
		def proportion_variance_poblation(proportion, n_sample, n_poblation)
            q=1.0-proportion
            ((proportion*q) / n_sample ) * continuity_correction(n_sample,n_poblation)
        end
        # Estimación del total, de acuerdo a poblacion
        def total_variance_poblation(proportion, n_sample, n_poblation)
            q=1.0-proportion
            ((n_poblation**2 * (proportion*q)) / n_sample) * continuity_correction(n_sample,n_poblation)
        end
        def proportion_variance_sample(proportion, n_sample, n_poblation)
            q=1.0-proportion
            ((n_poblation-n_sample) / ((n_sample - 1)*n_poblation))* proportion*q 
        end
        def total_variance_sample(proportion, n_sample, n_poblation)
            q=1.0-proportion
            ((n_poblation*(n_poblation-n_sample)) / (n_sample-1))*proportion*q
        end
        def proportion_confidence_interval_t(p, n_sample, n_population, margin=0.95)
            t=GSL::Cdf.tdist_Pinv(1-((1-margin) / 2),n_sample-1)
            proportion_confidence_interval(p,n_sample,n_population, t)
        end
        def proportion_confidence_interval_z(p, n_sample, n_population, margin=0.95)
            t=GSL::Cdf.ugaussian_Pinv(1-((1-margin) / 2))
            proportion_confidence_interval(p,n_sample,n_population, t)
        end
        def proportion_confidence_interval(p,n_sample,n_population, x)
            f=n_sample.to_f / n_population
            one_range=(x * Math::sqrt(1-f) * Math::sqrt(p * (1-p) / (n_sample-1))) + (1 / 2*n_sample)
            [p-one_range, p+one_range]
        end
        def proportion_standard_deviation(p, n_sample,n_population)
            f=n_sample.to_f / n_population
            (Math::sqrt(1-f) * Math::sqrt(p * (1-p) / (n_sample-1))) + (1 / 2*n_sample)
        end
        
        
        def standard_error_sample(s,n_sample,n_population)
            f=n_sample.to_f / n_population
            (s.to_f/Math::sqrt(n_sample))*Math::sqrt(1-f)
        end
        def mean_confidence_interval_t(mean,s,n_sample,n_population,margin=0.95)
            t=GSL::Cdf.tdist_Pinv(1-((1-margin) / 2),n_sample-1)
            mean_confidence_interval(mean,s,n_sample,n_population,t)
        end
        def mean_confidence_interval_z(mean,s,n_sample,n_population,margin=0.95)
            t=GSL::Cdf.ugaussian_Pinv(1-((1-margin) / 2))
            mean_confidence_interval(mean,s,n_sample,n_population, t)
        end
        def mean_confidence_interval(mean,s,n_sample,n_population,t)
            range=t*standard_error_sample(s,n_sample,n_population)
            [mean-range,mean+range]
        end
    end
    
end

