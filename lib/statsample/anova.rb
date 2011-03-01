module Statsample
  module Anova
    class << self
      def oneway(*args)
        OneWay.new(*args)
      end      
      def twoway(*args)
        TwoWay.new(*args)
      end      
      
      def oneway_with_vectors(*args)
        OneWayWithVectors.new(*args)
      end
      def twoway_with_vectors(*args)
        TwoWayWithVectors.new(*args)
      end
      
    end
  end
end

require 'statsample/anova/oneway'
require 'statsample/anova/contrast'
require 'statsample/anova/twoway'
