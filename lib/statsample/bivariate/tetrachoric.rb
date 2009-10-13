module Statsample
  module Bivariate
    # Calculate Tetrachoric correlation for two vectors.
    def self.tetrachoric(v1,v2)
      tc=Tetrachoric.new_with_vectors(v1,v2)
      tc.r
    end
    
    # Tetrachoric correlation matrix.
    # Order of rows and columns depends on Dataset#fields order
    def self.tetrachoric_correlation_matrix(ds)
      ds.collect_matrix do |row,col|
        if row==col
          1.0
        else
          begin
            tetrachoric(ds[row],ds[col])
          rescue RuntimeError
            nil
          end
        end
      end
    end
    #
    # Compute tetrachoric correlation.
    # 
    # See http://www.john-uebersax.com/stat/tetra.htm for extensive documentation about tetrachoric correlation
    # This class uses algorithm AS116 from Applied Statistics(1977) 
    # vol.26, no.3.
    # You can see FORTRAN code on http://lib.stat.cmu.edu/apstat/116
    # 
    # <b>Usage</b>.
    # With two variables x and y on a crosstab like this:
    # 
    #         -------------
    #         | y=0 | y=1 |
    #         -------------
    #   x = 0 |  a  |  b  |
    #         -------------
    #   x = 1 |  c  |  d  |
    #         -------------
    #
    # Use:
    #   tc=Statsample::Bivariate::Tetrachoric.new(a,b,c,d)
    #   tc.r # correlation
    #   tc.se # standard error
    #   tc.threshold_y # threshold for y variable
    #   tc.threshold_x # threshold for x variable
    
    
    class Tetrachoric
      
      attr_reader :r
      
      TWOPI=Math::PI*2
      SQT2PI= 2.50662827
      RLIMIT = 0.9999
      RCUT= 0.95
      UPLIM= 5.0
      CONST= 1E-36
      CHALF= 1E-18
      CONV  =1E-8
      CITER = 1E-6
      NITER = 25
      X=[0,0.9972638618,  0.9856115115,  0.9647622556, 0.9349060759,  0.8963211558, 0.8493676137, 0.7944837960, 0.7321821187, 0.6630442669, 0.5877157572, 0.5068999089, 0.4213512761, 0.3318686023, 0.2392873623, 0.1444719616, 0.0483076657]
      W=[0, 0.0070186100,  0.0162743947,  0.0253920653, 0.0342738629,  0.0428358980,  0.0509980593, 0.0586840935,  0.0658222228,  0.0723457941, 0.0781938958, 0.0833119242, 0.0876520930, 0.0911738787, 0.0938443991, 0.0956387201, 0.0965400885]
      # Creates a Tetrachoric object based on two vectors.
      # The vectors are dichotomized previously.
      def self.new_with_vectors(v1,v2)
        v1a,v2a=Statsample.only_valid(v1,v2)
        v1a=v1a.dichotomize
        v2a=v2a.dichotomize
        raise "v1 have only 0" if v1a.factors==[0]
        raise "v2 have only 0" if v2a.factors==[0]
        a,b,c,d = 0,0,0,0
        v1a.each_index{|i|
          x,y=v1a[i],v2a[i]
          a+=1 if x==0 and y==0
          b+=1 if x==0 and y==1
          c+=1 if x==1 and y==0
          d+=1 if x==1 and y==1
        }
        Tetrachoric.new(a,b,c,d)
      end
      # Standard error
      def se
        @sdr
      end
      # Threshold for variable x (rows)
      def threshold_x
        @zac
      end

      # Threshold for variable y (columns)
      def threshold_y
        @zab
      end
      
      def initialize(a,b,c,d)
        @a,@b,@c,@d=a,b,c,d
        #
        #       CHECK IF ANY CELL FREQUENCY IS NEGATIVE
        #
        raise "All frequencies should be positive" if  (@a < 0 or @b < 0 or @c < 0  or @d < 0)        
        compute
      end
      
      def compute
      
      #
      # INITIALIZATION
      #
      @r = 0
      sdzero = 0
      @sdr = 0
      @itype = 0
      @ifault = 0
      
      #
      #       CHECK IF ANY FREQUENCY IS 0.0 AND SET kdelta
      #
      @kdelta = 1
      delta  = 0
      @kdelta  = 2 if (@a == 0 or @d == 0) 
      @kdelta += 2 if (@b == 0 or @c == 0) 
      #
      #        kdelta=4 MEANS TABLE HAS 0.0 ROW OR COLUMN, RUN IS TERMINATED
      #

      raise "Rows and columns should have more than 0 items" if @kdelta==4

      #      GOTO (4, 1, 2 , 92), kdelta
      #
      #        delta IS 0.0, 0.5 OR -0.5 ACCORDING TO WHICH CELL IS 0.0
      #
      
      if(@kdelta==2)
        # 1
        delta=0.5
        @r=-1 if (@a==0 and @d==0)
      elsif(@kdelta==3)
        # 2
        delta=-0.5
        @r=1 if (@b==0 and @c==0)
      end
      # 4
      if @r!=0
        @itype=3
      end

      #
      #        STORE FREQUENCIES IN  AA, BB, CC AND DD
      #
      @aa = @a + delta
      @bb = @b - delta
      @cc = @c - delta
      @dd = @d + delta
      @tot = @aa+@bb+@cc+@dd
      #
      #        CHECK IF CORRELATION IS NEGATIVE, 0.0, POSITIVE
      #        IF (AA * DD - BB * CC) 7, 5, 6

      corr_dir=@aa * @dd - @bb * @cc
      if(corr_dir < 0)
      # 7
        @probaa = @bb.quo(@tot)
        @probac = (@bb + @dd).quo(@tot)
        @ksign = 2
        # ->  8
      else
        if (corr_dir==0)
          # 5
          @itype=4
        end
        # 6
        #
        #        COMPUTE PROBABILITIES OF QUADRANT AND OF MARGINALS
        #        PROBAA AND PROBAC CHOSEN SO THAT CORRELATION IS POSITIVE.
        #        KSIGN INDICATES WHETHER QUADRANTS HAVE BEEN SWITCHED
        #
        
        @probaa = @aa.quo(@tot)
        @probac = (@aa+@cc).quo(@tot)
        @ksign=1
      end
      # 8
      
      @probab = (@aa+@bb).quo(@tot)
          
      #
      #        COMPUTE NORMAL DEVIATES FOR THE MARGINAL FREQUENCIES
      #        SINCE NO MARGINAL CAN BE 0.0, IE IS NOT CHECKED
      #
      @zac = Distribution::Normal.p_value(@probac)
      @zab = Distribution::Normal.p_value(@probab)
      @ss = Math::exp(-0.5 * (@zac ** 2 + @zab ** 2)).quo(TWOPI)
      #
      #        WHEN R IS 0.0, 1.0 OR -1.0, TRANSFER TO COMPUTE SDZERO
      #
      if (@r != 0 or @itype > 0) 
        compute_sdzero
        return true
      end
      #
      #        WHEN MARGINALS ARE EQUAL, COSINE EVALUATION IS USED
      #
      if (@a == @b and @b == @c) 
        calculate_cosine
        return true
      end
      #
      #        INITIAL ESTIMATE OF CORRELATION IS YULES Y
      #
      @rr = ((Math::sqrt(@aa * @dd) - Math::sqrt(@bb * @cc)) ** 2)  / (@aa * @dd - @bb * @cc).abs
      @iter = 0
      begin
        #
        #        IF RR EXCEEDS RCUT, GAUSSIAN QUADRATURE IS USED
        #
        #10
        if @rr>RCUT
          gaussian_quadrature 
          return true
        end
        #
        #        TETRACHORIC SERIES IS COMPUTED
        #
        #        INITIALIZATION
        #
        va=1.0
        vb=@zac.to_f
        wa=1.0
        wb=@zab.to_f
        term = 1.0
        iterm = 0.0
        @sum = @probab * @probac
        deriv = 0.0
        sr = @ss
        #15
        begin
          if(sr.abs<=CONST)
            #
            #        RESCALE TERMS TO AVOID OVERFLOWS AND UNDERFLOWS
            #
            sr = sr  / CONST
            va = va * CHALF
            vb = vb * CHALF
            wa = wa * CHALF
            wb = wb * CHALF
          end
          #
          #        FORM SUM AND DERIVATIVE OF SERIES
          #
          #  20 
          dr = sr * va * wa
          sr = sr * @rr / term
          cof = sr * va * wa
          #
          #        ITERM COUNTS NO. OF CONSECUTIVE TERMS  <  CONV
          #
          iterm+=  1
          iterm=0 if (cof.abs > CONV)
          @sum = @sum + cof
          deriv += dr
          vaa = va
          waa = wa
          va = vb
          wa = wb
          vb = @zac * va - term * vaa
          wb = @zab * wa - term * waa
          term += 1
        end while (iterm < 2 or term < 6)
        #
        #        CHECK IF ITERATION CONVERGED
        #
        if((@sum-@probaa).abs <= CITER)
          @itype=term
          calculate_sdr
          return true
        end
        #
        #        CALCULATE NEXT ESTIMATE OF CORRELATION
        #
        #25
        @iter += 1
        #
        #        IF TOO MANY ITERATlONS, RUN IS TERMINATED
        #
        delta = (@sum - @probaa) /  deriv
        @rrprev = @rr
        @rr = @rr - delta
        @rr += 0.5 * delta if(@iter == 1) 
        @rr= RLIMIT if (@rr > RLIMIT)
        @rr =0 if (@rr  <  0.0)
      end while @iter < NITER
      raise "Too many iteration"
    #  GOTO 10
    end
      # GAUSSIAN QUADRATURE
      # 40
      def gaussian_quadrature
        if(@iter==0)
          # INITIALIZATION, IF THIS IS FIRST ITERATION
          @sum=@probab*@probac
          @rrprev=0
        end
        
        # 41 
        sumprv = @probab - @sum
        @prob = @bb.quo(@tot)
        @prob = @aa.quo(@tot) if (@ksign == 2)
        @itype = 1
        #
        # LOOP TO FIND ESTIMATE OF CORRELATION
        #  COMPUTATION OF INTEGRAL (SUM) BY QUADRATURE
        #
        # 42
        
        begin
          rrsq = Math::sqrt(1 - @rr ** 2)
          amid = 0.5 * (UPLIM + @zac)
          xlen = UPLIM - amid
          @sum = 0
          (1..16).each do |iquad|
            xla = amid + X[iquad] * xlen
            xlb = amid - X[iquad] * xlen
            
            
            #
            #       TO AVOID UNDERFLOWS, TEMPA AND TEMPB ARE USED
            #
            tempa = (@zab - @rr * xla) / rrsq
            if (tempa >= -6.0)
              @sum = @sum + W[iquad] * Math::exp(-0.5  * xla ** 2) * Distribution::Normal.cdf(tempa)
            end
            tempb = (@zab - @rr * xlb) / rrsq
            
            if (tempb >= -6.0)
              @sum = @sum + W[iquad] * Math::exp(-0.5 * xlb ** 2) * Distribution::Normal.cdf(tempb)
            end
          end # 44 ~ iquad
          @sum=@sum*xlen / SQT2PI
          #
          # CHECK IF ITERATION HAS CONVERGED
          # 
          if ((@prob - @sum).abs <= CITER) 
            calculate_sdr
            return true
          end
          # ESTIMATE CORRELATION FOR NEXT ITERATION BY LINEAR INTERPOLATION
          
          rrest = ((@prob -  @sum) * @rrprev - (@prob - sumprv) * @rr) / (sumprv - @sum)
          rrest = RLIMIT if (rrest > RLIMIT) 
          rrest = 0 if (rrest < 0) 
          @rrprev = @rr
          @rr = rrest
          sumprv = @sum
          #
          #        if estimate has same value on two iterations, stop iteration
          #
          if @rr == @rrprev 
            calculate_sdr
            return true
          end
          
          
        end while @iter < NITER 
        raise "Too many iterations"
        # ir a 42
      end
      def calculate_cosine
        #
        #        WHEN ALL MARGINALS ARE EQUAL THE COSINE FUNCTION IS USED
        #
        @rr = -Math::cos(TWOPI * @probaa)
        @itype = 2
        calculate_sdr
      end
      
      
      def calculate_sdr
        #
        # COMPUTE SDR
        #
        @r = @rr
        rrsq = Math::sqrt(1.0 - @r ** 2) 
        @itype = -@itype if (@kdelta > 1)
        if (@ksign != 1) 
          @r = -@r
          @zac = -@zac
        end
        # 71
        pdf = Math::exp(-0.5 * (@zac ** 2 - 2 * @r * @zac * @zab + @zab ** 2)  / rrsq ** 2) / (TWOPI * rrsq)
        @pac = Distribution::Normal.cdf((@zac - @r * @zab) / rrsq) - 0.5
        @pab = Distribution::Normal.cdf((@zab - @r * @zac) / rrsq) - 0.5
        @sdr = ((@aa+@dd) * (@bb + @cc)).quo(4) + @pab ** 2 * (@aa + @cc) * (@bb + @dd) + @pac ** 2 * (@aa + @bb) * (@cc + @dd) + 2.0 * @pab * @pac * (@aa * @dd - @bb * @cc) - @pab * (@aa * @bb - @cc * @dd) - @pac * (@aa * @cc - @bb * @dd)
        @sdr=0 if (@sdr<0)
        @sdr= Math::sqrt(@sdr) / (@tot * pdf * Math::sqrt(@tot))
        compute_sdzero
      end
      
      # 85
      #
      #        COMPUTE SDZERO
      #
      def compute_sdzero
        @sdzero = Math::sqrt(((@aa + @bb) * (@aa + @cc) * (@bb + @dd) * (@cc + @dd)).quo(@tot)).quo(@tot ** 2 * @ss)
        @sdr = @sdzero if (@r == 0)
      end
    end
  end
end


