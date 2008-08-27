module RubySS
    # Based on Babatunde, Iyiola & Eni () : 
    # "A Numerical Procedure for Computing Chi-Square Percentage Points"
    # 
    module ChiDistribution
        class << self
            def steps(av, bv, itv)
                steps = ((bv.to_f - av.to_f) / itv.to_f).to_i
            end
            def loggamma(k)
            c1 = 76.18009173
            c2 = -86.50532033
            c3 = 24.01409822
            c4 = -1.231739516
            c5 = 0.00120858
            c6 = -0.000005364
            c7 = 2.506628275
            x1 = k - 1
            ws = x1 + 5.5
            ws = (x1 + 0.5) * Math::log(ws) - ws
            s = 1 + c1 / (x1 + 1) + c2 / (x1 + 2) + c3 / (x1 + 3) + c4 / (x1 + 4) + c5 / (x1 + 5) + c6 / (x1 + 6)
            ws + Math::log(c7 * s)
            end
            def f(x, k)
                Math::exp(0.5 * k * Math::log(0.5 * x) - Math::log(x) - loggamma(0.5 * k) - 0.5 * x)
            end
            def cdf(b,k)
                a = 0.001
                b=b.to_f
                if k==2
                    1 - Math::exp( -b.to_f / 2)
                else
                    w = (b - a) / 28.to_f
                    2 * w / 45 * (7 * (f(a, k) + f(a + 28 * w, k)) + 12 * (f(a + 2 * w, k) +  f(a + 6 * w, k) + f(a + 10 * w, k) + f(a + 14 * w, k) + f(a + 18 * w, k) + f(a + 22 * w, k) + f(a + 26 * w, k)) + 14 * (f(a + 4 * w, k) + f(a + 8 * w, k) + f(a + 12 * w, k) + f(a + 16 * w, k) + f(a + 20 * w, k) + f(a + 24 * w, k)) + 32 * (f(a + w, k) + f(a + 3 * w, k) + f(a + 5 * w, k) + f(a + 7 * w, k) + f(a + 9 * w, k) + f(a + 11 * w, k) + f(a + 13 * w, k) + f(a + 15 * w, k) + f(a + 17 * w, k) + f(a + 19 * w, k) + f(a + 21 * w, k) + f(a + 23 * w, k) + f(a + 25 * w, k) + f(a + 27 * w, k)))
                end
            end
        end
    end
end
