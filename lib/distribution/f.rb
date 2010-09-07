module Distribution
  # Calculate cdf and inverse cdf for Fisher Distribution.
  # Uses Statistics2 module
  module F
    class << self
      # Return the P-value of the corresponding integral with 
      # k degrees of freedom
      #
      #   Distribution::F.p_value(0.95,1,2)
      def p_value(pr,k1,k2)
        # Statistics2 has some troubles with extreme f values
        if Distribution.has_gsl?
          GSL::Cdf.fdist_Pinv(pr,k1,k2)
        else
          #puts "F:#{k1}, #{k2},#{pr}"
          Statistics2.pfdist(k1,k2, pr)
        end
      end
      # F cumulative distribution function (cdf).
      # 
      # Returns the integral of F-distribution 
      # with k1 and k2 degrees of freedom
      # over [0, x].
      #   Distribution::F.cdf(20,3,2)
      # 
      def cdf(x, k1, k2)
        if Distribution.has_gsl?
          GSL::Cdf.fdist_P(x.to_f,k1,k2)
        else
          Statistics2.fdist(k1, k2,x)
        end
      end
    end
  end
end
