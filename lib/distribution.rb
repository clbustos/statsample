require 'statistics2'
# Several distributions modules to calculate cdf, inverse cdf and pdf
# See Distribution::Pdf for interface.
# 
# Usage:
#    Distribution::Normal.cdf(1.96)
#    => 0.97500210485178
#    Distribution::Normal.p_value(0.95)
#    => 1.64485364660836
module Distribution
    autoload(:ChiSquare, 'distribution/chisquare')
    autoload(:T, 'distribution/t')
    autoload(:F, 'distribution/f')
    autoload(:Normal, 'distribution/normal')
    
end
