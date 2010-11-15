module Statsample
	# Several methods to estimate parameters for simple random sampling
  # == Reference: 
  # * Cochran, W.(1972). Sampling Techniques [spanish edition].
  # * http://stattrek.com/Lesson6/SRS.aspx
  
	module SRS

		class << self
      ########################
      #
      # :SECTION: Proportion estimation
      #
      # Function for estimation of proportions
      ########################
      
      #
      # Finite population correction (over variance)
      # Source: Cochran(1972)
      def fpc_var(sam,pop)
          (pop - sam).quo(pop - 1)
      end
      # Finite population correction (over standard deviation)
      def fpc(sam,pop)
          Math::sqrt((pop-sam).quo(pop-1))
      end
      
      # Non sample fraction.
      #
      # 1 - sample fraction
      def qf(sam , pop)
          1-(sam.quo(pop))
      end
      # Sample size estimation for proportions, infinite poblation
      def estimation_n0(d,prop,margin=0.95)
          t=Distribution::Normal.p_value(1-(1-margin).quo(2))
          var=prop*(1-prop)
          t**2*var.quo(d**2)
      end
      # Sample size estimation for proportions, finite poblation.
      def estimation_n(d,prop,n_pobl,margin=0.95)
          n0=estimation_n0(d,prop,margin)
          n0.quo( 1 + ((n0 - 1).quo(n_pobl)))
      end
      
      
      # Proportion confidence interval with t values
      # Uses estimated proportion, sample without replacement.
      
      def proportion_confidence_interval_t(prop, n_sample, n_population, margin=0.95)
          t = Distribution::T.p_value(1-((1-margin).quo(2)) , n_sample-1)
          proportion_confidence_interval(prop,n_sample,n_population, t)
      end
      
      # Proportion confidence interval with z values
      # Uses estimated proportion, sample without replacement.
      def proportion_confidence_interval_z(p, n_sample, n_population, margin=0.95)
          z=Distribution::Normal.p_value(1-((1-margin).quo(2)))
          proportion_confidence_interval(p,n_sample,n_population, z)
      end
      # Proportion confidence interval with x value
      # Uses estimated proportion, sample without replacement
      
      def proportion_confidence_interval(p, sam,pop , x)
          #f=sam.quo(pop)
          one_range=x * Math::sqrt((qf(sam, pop) * p * (1-p)).quo(sam-1)) + (1.quo(sam * 2.0))
          [p-one_range, p+one_range]
      end
      # Standard deviation for sample distribution of a proportion
      # Know proportion, sample with replacement.
      # Based on http://stattrek.com/Lesson6/SRS.aspx
      def proportion_sd_kp_wr(p, n_sample)
          Math::sqrt(p*(1-p).quo(n_sample))
      end
      # Standard deviation for sample distribution of a proportion
      # Know proportion, sample without replacement.
      #
      # Sources: 
      # * Cochran(1972)
      def proportion_sd_kp_wor(p, sam, pop)
          fpc(sam,pop)*Math::sqrt(p*(1-p).quo(sam))
      end
      # Standard deviation for sample distribution of a proportion
      # Estimated proportion, sample with replacement
      # Based on http://stattrek.com/Lesson6/SRS.aspx.
      def proportion_sd_ep_wr(p, n_sample)
          Math::sqrt(p*(1-p).quo(n_sample-1))
      end                                       
      # Standard deviation for sample distribution of a proportion.
      # Estimated proportion, sample without replacement.
      # Reference: 
      # * Cochran, 1972, Técnicas de muestreo
      def proportion_sd_ep_wor(p, sam,pop)
          fsc=(pop-sam).quo((sam-1)*pop)
          Math::sqrt(fsc*p*(1-p))
      end
      
      # Total estimation sd based on sample. 
      # Known proportion, sample without replacement
      # Reference: 
      # * Cochran(1972)
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
      # :SECTION:  Mean stimation
      #
      ########################

      
      # Standard error. Known variance, sample with replacement.
      def standard_error_ksd_wr(s, sam, pop)
          s.quo(Math::sqrt(sam)) * Math::sqrt((pop-1).quo(pop))
      end
      
      # Standard error of the mean. Known variance, sample w/o replacement
      def standard_error_ksd_wor(s,sam,pop)
          s.quo(Math::sqrt(sam)) * Math::sqrt(qf(sam,pop)) 
      end
      
      alias_method :standard_error_esd_wr, :standard_error_ksd_wr
      
      # Standard error of the mean. 
      # Estimated variance, without replacement
      # Cochran (1972) p.47
      def standard_error_esd_wor(s,sam,pop)
          s.quo(Math::sqrt(sam)) * Math::sqrt(qf(sam,pop))
      end
      
      alias_method :standard_error, :standard_error_esd_wor
      alias_method :se, :standard_error_esd_wor

      # Standard error of total estimation
      
      def standard_error_total(s,sam,pop)
          pop*se(s,sam,pop)
      end

      # Confidence Interval using T-Student
      # Use with n < 60
      def mean_confidence_interval_t(mean,s,n_sample,n_population,margin=0.95)
          t=Distribution::T.p_value(1-((1-margin) / 2),n_sample-1)
          mean_confidence_interval(mean,s,n_sample,n_population,t)
      end
      # Confidente Interval using Z
      # Use with n > 60
      def mean_confidence_interval_z(mean,s,n_sample,n_population,margin=0.95)
          z=Distribution::Normal.p_value(1-((1-margin) / 2))
          mean_confidence_interval(mean,s,n_sample,n_population, z)
      end
      # Confidente interval using X.
      #
      # Better use mean_confidence_interval_z or mean_confidence_interval_t
      def mean_confidence_interval(mean,s,n_sample,n_population,x)
          range=x*se(s,n_sample,n_population)
          [mean-range,mean+range]
      end
		end
	end
end
