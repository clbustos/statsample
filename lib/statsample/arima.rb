require 'debugger'
module Statsample
  module ARIMA
    class ARIMA < Statsample::TimeSeries

      def arima(ds, p, i, q)
        if q.zero? 
          self.ar(p)
        elsif p.zero?
          self.ma(p)
        end
      end

      def ar(p)
        #AutoRegressive part of model
        #http://en.wikipedia.org/wiki/Autoregressive_model#Definition
        #For finding parameters(to fit), we will use either Yule-walker
        #or Burg's algorithm(more efficient)

        degugger

      end

      def yule_walker()
      end
    end
  end
end
