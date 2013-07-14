module Statsample
  module TimeSeries
    module Pacf
      class Pacf

        def self.pacf_yw(timeseries, max_lags, method = 'yw')
          #partial autocorrelation by yule walker equations.
          #Inspiration: StatsModels
          pacf = [1.0]
          (1..max_lags).map do |i|
            pacf << yule_walker(timeseries, i, method)[-1]
          end
          pacf
        end

        def self.yule_walker(ts, k = 1, method='yw')
          #From the series, estimates AR(p)(autoregressive) parameter
          #using Yule-Waler equation. See -
          #http://en.wikipedia.org/wiki/Autoregressive_moving_average_model

          #parameters:
          #ts = series
          #k = order, default = 1
          #method = can be 'yw' or 'mle'. If 'yw' then it is unbiased, denominator
          #is (n - k)

          #returns:
          #rho => autoregressive coefficients
          ts = ts - ts.mean
          n = ts.size
          if method.downcase.eql? 'yw'
            #unbiased => denominator = (n - k)
            denom =->(k) { n - k }
          else
            #mle
            #denominator => (n)
            denom =->(k) { n }
          end
          r = Array.new(k + 1) { 0.0 }
          r[0] = ts.map { |x| x ** 2 }.inject(:+).to_f / denom.call(0).to_f

          1.upto(k) do |l|
            r[l] = (ts[0...-l].zip(ts[l...ts.size])).map do |x|
              x.inject(:*)
            end.inject(:+).to_f / denom.call(l).to_f
          end

          r_R = toeplitz(r[0...-1])

          mat = Matrix.columns(r_R).inverse()
          solve_matrix(mat, r[1..r.size])
        end

        def self.toeplitz(arr)
          #Generates Toeplitz matrix -
          #http://en.wikipedia.org/wiki/Toeplitz_matrix
          #Toeplitz matrix are equal when they are stored in row &
          #column major
          #=> arr = [0, 1, 2, 3]
          #=> result:
          #[[0, 1, 2, 3],
          # [1, 0, 1, 2],
          # [2, 1, 0, 1],
          # [3, 2, 1, 0]]
          eplitz_matrix = Array.new(arr.size) { Array.new(arr.size) }

          0.upto(arr.size - 1) do |i|
            j = 0
            index = i
            while i >= 0 do
              eplitz_matrix[index][j] = arr[i]
              j += 1
              i -= 1
            end
            i = index + 1; k = 1
            while i < arr.size do
              eplitz_matrix[index][j] = arr[k]
              i += 1; j += 1; k += 1
            end
          end
          eplitz_matrix
        end

        def self.solve_matrix(matrix, out_vector)
          solution_vector = Array.new(out_vector.size, 0)
          matrix = matrix.to_a
          k = 0
          matrix.each do |row|
            row.each_with_index do |element, i|
              solution_vector[k] += element * 1.0 * out_vector[i]
            end
            k += 1
          end
          solution_vector
        end

      end
    end
  end
end
