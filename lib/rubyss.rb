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
        # Finite sample correction for variance
        # Source: Cochran(1972)
        def fsc(sam,pop)
            ((pop - sam).to_f / ( pop - 1))
        end
        # 1 - sample fraction
        def qf(sam,pop)
            1-(sam.to_f/pop)
        end
              
        
        ########################
        #
        # Proportion estimation
        #
        ########################
        
        
        # Proportion confidence interval with t values
        # Uses estimated proportion, sample without replacement.
        
        def proportion_confidence_interval_t(p, n_sample, n_population, margin=0.95)
            t=GSL::Cdf.tdist_Pinv(1-((1-margin) / 2),n_sample-1)
            proportion_confidence_interval(p,n_sample,n_population, t)
        end
        # Proportion confidence interval with z values
        # Uses estimated proportion, sample without replacement.
        def proportion_confidence_interval_z(p, n_sample, n_population, margin=0.95)
            z=GSL::Cdf.ugaussian_Pinv(1-((1-margin) / 2))
            proportion_confidence_interval(p,n_sample,n_population, z)
        end
        # Proportion confidence interval with x value
        # Uses estimated proportion, sample without replacement
        
        def proportion_confidence_interval(p,sam,pop, x)
            f=sam.to_f/pop
            one_range=x * Math::sqrt((qf(sam, pop) * p * (1-p)) / (sam-1)) + (1/(sam * 2.0))
            [p-one_range, p+one_range]
        end
        # Standard deviation for sample distribution of a proportion
        # Know proportion, sample with replacement.
        # Based on http://stattrek.com/Lesson6/SRS.aspx
        def proportion_sd_kp_wr(p, n_sample)
            Math::sqrt(p*(1-p) / n_sample)
        end
        # Standard deviation for sample distribution of a proportion
        # Know proportion, sample without replacement.
        # Sources: 
        # - http://stattrek.com/Lesson6/SRS.aspx
        # - Cochran
        def proportion_sd_kp_wor(p, sam, pop)
            Math::sqrt(RubySS::fsc(sam,pop) * p*(1-p) / sam.to_f)
        end
        # Standard deviation for sample distribution of a proportion
        # Estimated proportion, sample with replacement
        # Based on http://stattrek.com/Lesson6/SRS.aspx.
        def proportion_sd_ep_wr(p, n_sample)
            Math::sqrt(p*(1-p) / (n_sample-1))
        end                                       
        # Standard deviation for sample distribution of a proportion.
        # Estimated proportion, sample without replacement.
        # Source: Cochran, 1972, Técnicas de muestreo
        def proportion_sd_ep_wor(p, sam,pop)
            fsc=(pop-sam).to_f / ((sam-1)*pop)
            Math::sqrt(fsc*p*(1-p))
        end
        
         # Total estimation sd based on sample. 
        # Known proportion, sample without replacement
        # Source: Cochran(1972)
        def proportion_total_sd_kp_wor(prop, sam, pop)
            pob * proportion_sd_kp_wor(p, sam, pop)
        end
        # Total estimation sd based on sample. 
        # Estimated proportion, sample without replacement
        # Source: Cochran(1972)
        def proportion_total_sd_ep_wor(prop, sam, pop)
            fsc=((pop - sam).to_f / ( sam - 1))
            Math::sqrt(fsc*pop*prop*(1-prop))
        end 
        
        ########################
        #
        # Mean stimation
        #
        ########################

        
        # Standard error. Known variance, sample with replacement.
        def standard_error_ksd_wr(s,sam,pop)
            #s.to_f/Math::sqrt(sam)
            (s.to_f/Math::sqrt(sam)) * Math::sqrt((pop-1).to_f / pop)
        end
        
        # Standard error of the mean. Known variance, sample w/o replacement
        def standard_error_ksd_wor(s,sam,pop)
            (s.to_f/Math::sqrt(sam)) * Math::sqrt(qf(sam,pop)) 
            #* (pop.to_f/(pop-1))
        end
        
        alias_method :standard_error_esd_wr, :standard_error_ksd_wr
        
        # Standard error of the mean. 
        # Estimated variance, without replacement
        # Cochran (1972) p.47
        def standard_error_esd_wor(s,sam,pop)
            (s.to_f / Math::sqrt(sam)) * Math::sqrt(qf(sam,pop))
        end
        
        alias_method :standard_error, :standard_error_esd_wor
        alias_method :se, :standard_error_esd_wor

        
        def standard_error_total(s,sam,pop)
            pop*se(s,sam,pop)
        end

        # Confidence Interval using T-Student
        # Use with samples < 60.
        def mean_confidence_interval_t(mean,s,n_sample,n_population,margin=0.95)
            t=GSL::Cdf.tdist_Pinv(1-((1-margin) / 2),n_sample-1)
            mean_confidence_interval(mean,s,n_sample,n_population,t)
        end
        def mean_confidence_interval_z(mean,s,n_sample,n_population,margin=0.95)
            t=GSL::Cdf.ugaussian_Pinv(1-((1-margin) / 2))
            mean_confidence_interval(mean,s,n_sample,n_population, t)
        end
        def mean_confidence_interval(mean,s,n_sample,n_population,t)
            range=t*se(s,n_sample,n_population)
            [mean-range,mean+range]
        end
        
        #########################################
        #
        # Mean stimation for stratified sample
        #
        #########################################
        
        
    end
    
end

