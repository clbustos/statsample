#   statistics2.rb
#
#   distributions of statistics             
#     by Shin-ichiro HARA
# URL: http://blade.nagaokaut.ac.jp/~sinara/ruby/math/
#
#   2003.09.25
#
#   Ref:
#     [1] http://www.matsusaka-u.ac.jp/~okumura/algo/
#     [2] http://www5.airnet.ne.jp/tomy/cpro/sslib11.htm

module Statistics2
  SQ2PI = Math.sqrt(2 * Math::PI)

  # Newton approximation
  def newton_a(y, ini, epsilon = 1.0e-6, limit = 30)
    x = ini
    limit.times do |i|
      prev = x
      f, df = yield(prev)
      x = (y - f)/df + prev
      if (x - prev).abs < epsilon
        return x
      end
    end
    $stderr.puts("Warning(newton approximation): over limit")
    x
  end

  module_function :newton_a
  private :newton_a
  private_class_method :newton_a

  # Gamma function
  LOG_2PI = Math.log(2 * Math::PI)# log(2PI)
  N = 8
  B0  = 1.0
  B1  = -1.0 / 2.0
  B2  = 1.0 / 6.0
  B4  = -1.0 / 30.0
  B6  =  1.0 / 42.0
  B8  = -1.0 / 30.0
  B10 =  5.0 / 66.0
  B12 = -691.0 / 2730.0
  B14 =  7.0 / 6.0
  B16 = -3617.0 / 510.0
  
  def loggamma(x)
    v = 1.0
    while (x < N)
      v *= x
      x += 1.0
    end
    w = 1.0 / (x * x)
    ret = B16 / (16 * 15)
    ret = ret * w + B14 / (14 * 13)
    ret = ret * w + B12 / (12 * 11)
    ret = ret * w + B10 / (10 *  9)
    ret = ret * w + B8  / ( 8 *  7)
    ret = ret * w + B6  / ( 6 *  5)
    ret = ret * w + B4  / ( 4 *  3)
    ret = ret * w + B2  / ( 2 *  1)
    ret = ret / x + 0.5 * LOG_2PI - Math.log(v) - x + (x - 0.5) * Math.log(x)
    ret
  end
  
  def gamma(x)
    if (x < 0.0)
      return Math::PI / (Math.sin(Math.PI * x) * Math.exp(loggamma(1 - x))) #/
    end
    Math.exp(loggamma(x))
  end

  module_function :loggamma, :gamma
  private :loggamma, :gamma
  private_class_method :loggamma, :gamma

  #normal-distribution
  # (-\infty, z]
  def p_nor(z)
    if z < -12 then return 0.0 end
    if z > 12 then return 1.0 end
    if z == 0.0 then return 0.5 end

    if z > 0.0
      e = true
    else
      e = false
      z = -z
    end
    z = z.to_f
    z2 = z * z
    t = q = z * Math.exp(-0.5 * z2) / SQ2PI

    3.step(199, 2) do |i|
      prev = q
      t *= z2 / i
      q += t
      if q <= prev
        return(e ? 0.5 + q : 0.5 - q)
      end
    end
    e ? 1.0 : 0.0
  end

  # inverse of normal distribution ([2])
  # Pr( (-\infty, x] ) = qn -> x
  def pnorm(qn)
    b = [1.570796288, 0.03706987906, -0.8364353589e-3,
         -0.2250947176e-3, 0.6841218299e-5, 0.5824238515e-5,
         -0.104527497e-5, 0.8360937017e-7, -0.3231081277e-8,
         0.3657763036e-10, 0.6936233982e-12]
    
    if(qn < 0.0 || 1.0 < qn)
      $stderr.printf("Error : qn <= 0 or qn >= 1  in pnorm()!\n")
      return 0.0;
    end
    qn == 0.5 and return 0.0
    
    w1 = qn
    qn > 0.5 and w1 = 1.0 - w1
    w3 = -Math.log(4.0 * w1 * (1.0 - w1))
    w1 = b[0]
    1.upto 10 do |i|
      w1 += b[i] * w3**i;
    end
    qn > 0.5 and return Math.sqrt(w1 * w3)
    -Math.sqrt(w1 * w3)
  end

  private :p_nor, :pnorm
  module_function :p_nor, :pnorm
  private_class_method :p_nor, :pnorm

  #normal-distribution interface
  def normaldist(z)
    p_nor(z)
  end

  def pnormaldist(y)
    pnorm(y)
  end

  #chi-square distribution ([1])
  #[x, \infty)
  def q_chi2(df, chi2)
    chi2 = chi2.to_f
    if (df & 1) != 0
      chi = Math.sqrt(chi2)
      if (df == 1) then return 2 * normal___x(chi); end
      s = t = chi * Math.exp(-0.5 * chi2) / SQ2PI
      k = 3
      while k < df
        t *= chi2 / k;  s += t;
        k += 2
      end
      2 * (normal___x(chi) + s)
    else
      s = t = Math.exp(-0.5 * chi2)
      k = 2
      while k < df
        t *= chi2 / k;  s += t;
        k += 2
      end
      s
    end
  end

  def chi2dens(n, x)
    if n == 1
      1.0/Math.sqrt(2 * Math::PI * x) * Math::E**(-x/2.0)
    elsif n == 2
      0.5 * Math::E**(-x/2.0)
    else
      n = n.to_f
      n2 = n/2
      x = x.to_f
      1.0 / 2**n2 / gamma(n2) * x**(n2 - 1.0) * Math.exp(-x/2.0)
    end
  end

  # [x, \infty)
  # Pr([x, \infty)) = y -> x
  def pchi2(n, y)
    if n == 1
      w = pnorm(1 - y/2) # = pnormal___x(y/2)
      w * w
    elsif n == 2
#      v = (1.0 / y - 1.0) / 33.0
#      newton_a(y, v) {|x| [q_chi2(n, x), -chi2dens(n, x)] }
      -2.0 * Math.log(y)
    else
      eps = 1.0e-5
      v = 0.0
      s = 10.0
      loop do
        v += s
        if s <= eps then break end
        if (qe = q_chi2(n, v) - y) == 0.0 then break end
        if qe < 0.0
          v -= s
          s /= 10.0 #/
        end
      end
      v
    end
  end

  private :q_chi2, :pchi2, :chi2dens
  module_function :q_chi2, :pchi2, :chi2dens
  private_class_method :q_chi2, :pchi2, :chi2dens
  
  # chi-square-distribution interface
  def chi2dist(n, x); 1.0 - q_chi2(n, x); end
  def pchi2dist(n, y); pchi2(n, 1.0 - y); end


  # t-distribution ([1])
  # (-\infty, x]
  def p_t(df, t)
    c2 = df.to_f / (df + t * t);
    s = Math.sqrt(1.0 - c2)
    s = -s if t < 0.0
    p = 0.0;
    i = df % 2 + 2
    while i <= df
      p += s
      s *= (i - 1) * c2 / i
      i += 2
    end
    if df & 1 != 0
      0.5+(p*Math.sqrt(c2)+Math.atan(t/Math.sqrt(df)))/Math::PI
    else
      (1.0 + p) / 2.0
    end
  end

  # inverse of t-distribution ([2])
  # (-\infty, -q/2] + [q/2, \infty)
  def ptsub(q, n)
    q = q.to_f
    if(n == 1 && 0.001 < q && q < 0.01)
      eps = 1.0e-4
    elsif (n == 2 && q < 0.0001)
      eps = 1.0e-4
    elsif (n == 1 && q < 0.001)
      eps = 1.0e-2
    else
      eps = 1.0e-5
    end
    s = 10000.0
    w = 0.0
    loop do
      w += s
      if(s <= eps) then return w end
      if((qe = 2.0 - p_t(n, w)*2.0 - q) == 0.0) then return w end
      if(qe < 0.0)
        w -= s
        s /= 10.0 #/
      end
    end
  end

  def pt(q, n)
    q = q.to_f
    if(q < 1.0e-5 || q > 1.0 || n < 1)
      $stderr.printf("Error : Illigal parameter in pt()!\n")
      return 0.0
    end
    
    if(n <= 5) then return ptsub(q, n) end
    if(q <= 5.0e-3 && n <= 13) then return ptsub(q, n) end

    f1 = 4.0 * (f = n.to_f)
    f5 = (f4 = (f3 = (f2 = f * f) * f) * f) * f
    f2 *= 96.0
    f3 *= 384.0
    f4 *= 92160.0
    f5 *= 368640.0
    u = pnormaldist(1.0 - q / 2.0)

    w0 = (u2 = u * u) * u
    w1 = w0 * u2
    w2 = w1 * u2
    w3 = w2 * u2
    w4 = w3 * u2
    w = (w0 + u) / f1
    w += (5.0 * w1 + 16.0 * w0 + 3.0 * u) / f2
    w += (3.0 * w2 + 19.0 * w1 + 17.0 * w0 - 15.0 * u) / f3
    w += (79.0 * w3 + 776.0 * w2 + 1482.0 * w1 - 1920.0 * w0 - 9450.0 * u) / f4
    w += (27.0 * w4 + 339.0 * w3 + 930.0 * w2 - 1782.0 * w1 - 765.0 * w0 + 17955.0 * u) / f5
    u + w
  end
  
  private  :p_t, :pt, :ptsub
  module_function :p_t, :pt, :ptsub
  private_class_method :p_t, :pt, :ptsub

  # t-distribution interface
  def tdist(n, t); p_t(n, t); end
  def ptdist(n, y)
    if y > 0.5
      pt(2.0 - y*2.0, n)
    else
      - pt(y*2.0, n)
    end
  end

  # F-distribution ([1])
  # [x, \infty) 
  def q_f(df1, df2, f)
    if (f <= 0.0) then return 1.0; end
    if (df1 % 2 != 0 && df2 % 2 == 0)
      return 1.0 - q_f(df2, df1, 1.0 / f)
    end
    cos2 = 1.0 / (1.0 + df1.to_f * f / df2.to_f)
    sin2 = 1.0 - cos2

    if (df1 % 2 == 0)
        prob = cos2 ** (df2.to_f / 2.0)
        temp = prob
        i = 2
        while i < df1
          temp *= (df2.to_f + i - 2) * sin2 / i
          prob += temp
          i += 2
        end
        return prob
    end
    prob = Math.atan(Math.sqrt(df2.to_f / (df1.to_f * f)))
    temp = Math.sqrt(sin2 * cos2)
    i = 3
    while i <= df1
      prob += temp
      temp *= (i - 1).to_f * sin2 / i.to_f;
      i += 2.0
    end
    temp *= df1.to_f
    i = 3
    while i <= df2
      prob -= temp
      temp *= (df1.to_f + i - 2) * cos2 / i.to_f
      i += 2
    end
    prob * 2.0 / Math::PI
  end

  # inverse of F-distribution ([2])
  def pfsub(x, y, z)
    (Math.sqrt(z) - y) / x / 2.0
  end

  # [x, \infty)
  def pf(q, n1, n2)
    if(q < 0.0 || q > 1.0 || n1 < 1 || n2 < 1)
      $stderr.printf("Error : Illegal parameter in pf()!\n")
      return 0.0
    end
    
    if n1 <= 240 || n2 <= 240
      eps = 1.0e-5
      if(n2 == 1) then eps = 1.0e-4 end
      fw = 0.0
      s = 1000.0
      loop do
        fw += s
        if s <= eps  then return fw end
        if (qe = q_f(n1, n2, fw) - q) == 0.0 then return fw end
        if qe < 0.0
          fw -= s
          s /= 10.0 #/
        end
      end
    end

    eps = 1.0e-6
    qn = q
    if q < 0.5 then qn = 1.0 - q
      u = pnorm(qn)
      w1 = 2.0 / n1 / 9.0
      w2 = 2.0 / n2 / 9.0
      w3 = 1.0 - w1
      w4 = 1.0 - w2
      u2 = u * u
      a = w4 * w4 - u2 * w2
      b = -2. * w3 * w4
      c = w3 * w3 - u2 * w1
      d = b * b - 4 * a * c
      if(d < 0.0)
        fw = pfsub(a, b, 0.0)
      else
        if(a.abs > eps)
          fw = pfsub(a, b, d)
        else
          if(b.abs > eps) then return -c / b end
          fw = pfsub(a, b, 0.0)
        end
      end
      fw * fw * fw
    end
  end

  private  :q_f, :pf, :pfsub
  module_function :q_f, :pf, :pfsub
  private_class_method :q_f, :pf, :pfsub

  # F-distribution interface
  def fdist(n1, n2, f); 1.0 - q_f(n1, n2, f); end
  def pfdist(n1, n2, y); pf(1.0 - y, n1, n2); end

  ############################################################################
  # discrete distributions

  def perm(n, x = n)
    raise RangeError if n < 0 || x < 0
    r = 1
    while x >= 1
      r *= n
      n -= 1
      x -= 1
    end
    r
  end
  
  def combi(n, x)
    raise RangeError if n < 0 || x < 0
    x = n - x if x*2 > n
    perm(n, x) / perm(x, x)
  end

  module_function :perm, :combi
  private_class_method :perm, :combi

  def bindens(n, p, x)
    p = p.to_f
    q = 1.0 - p
    combi(n, x) * p**x * q**(n - x)
  end
  
  def bindist(n, p, x)
    (0..x).inject(0.0) do |s, k|
      s + bindens(n, p, k)
    end
  end

  def poissondens(m, x)
    return 0.0 if x < 0
    m = m.to_f
    m ** x * Math::E ** (-m) / perm(x)
  end

  def poissondist(m, x)
    (0..x).inject(0.0) do |s, k|
      s + poissondens(m, k)
    end
  end

  ############################################################################

  # normal-distribution
  def normalxXX_(z); normaldist(z); end
  def normal__X_(z); normaldist(z) - 0.5; end
  def normal___x(z); 1.0 - normaldist(z); end
  def normalx__x(z); 2.0 - normaldist(z) * 2.0; end
  module_function :normaldist, :normalxXX_, :normal__X_, :normal___x, :normalx__x

  # inverse of normal-distribution
  def pnormalxXX_(z); pnormaldist(z); end
  def pnormal__X_(y); pnormalxXX_(y + 0.5); end
  def pnormal___x(y); pnormalxXX_(1.0 - y); end
  def pnormalx__x(y); pnormalxXX_(1.0 - y/2.0); end
  module_function :pnormaldist, :pnormalxXX_, :pnormal__X_, :pnormal___x, :pnormalx__x


  # chi2-distribution
  def chi2_x(n, x); 1.0 - chi2dist(n, x); end
  def chi2X_(n, x); chi2dist(n, x); end
  module_function :chi2dist, :chi2X_, :chi2_x

  # inverse of chi2-distribution
  def pchi2_x(n, y); pchi2dist(n, 1.0 - y); end
  def pchi2X_(n, y); pchi2dist(n, y); end
  module_function :pchi2dist, :pchi2X_, :pchi2_x


  # t-distribution
  def tx__x(n, x); 2.0 - tdist(n, x) * 2.0; end
  def txXX_(n, x); tdist(n, x); end
  def t__X_(n, x); tdist(n, x) - 0.5; end
  def t___x(n, x); 1.0 - tdist(n, x); end
  module_function :tdist, :txXX_, :t__X_, :t___x, :tx__x

  # inverse of t-distribution
  def ptx__x(n, y); ptdist(n, 1.0 - y / 2.0); end
  def ptxXX_(n, y); ptdist(n, y); end
  def pt__X_(n, y); ptdist(n, 0.5 + y); end
  def pt___x(n, y); ptdist(n, 1.0 - y); end
  module_function :ptdist, :ptxXX_, :pt__X_, :pt___x, :ptx__x


  # F-distribution
  def f_x(n1, n2, x); 1.0 - fdist(n1, n2, x); end
  def fX_(n1, n2, x); fdist(n1, n2, x); end
  module_function :fdist, :fX_, :f_x

  # inverse of F-distribution
  def pf_x(n1, n2, x); pfdist(n1, n2, 1.0 - x); end
  def pfX_(n1, n2, x); pfdist(n1, n2, x); end
  module_function :pfdist, :pfX_, :pf_x

  # discrete distributions
  def binX_(n, p, x); bindist(n, p, x); end
  def bin_x(n, p, x); bindist(n, 1.0 - p, n - x);  end
  module_function :bindens, :bindist, :binX_, :bin_x

  def poissonX_(m, x); poissondist(m, x); end
  def poisson_x(m, x); 1.0 - poissondist(m, x-1); end
  module_function :poissondens, :poissondist, :poissonX_, :poisson_x
end


if $0 == __FILE__
  if ARGV.empty?
    puts "Example:"
    puts "        #$0 normaldist 0.01"
    puts "        #$0 pf_x 2 3 0.01"
    exit
  end
  p Statistics2.send(ARGV[0], *ARGV[1..-1].map{|x| eval(x)})
end
