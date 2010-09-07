module Statsample
  module Reliability
    # = Intra-class correlation
    # According to Shrout & Fleiss (1979, p.422): "ICC is the correlation 
    # between one measurement (either a single rating or a mean of 
    # several ratings) on a target and another measurement obtained on that target"
    # 
    # == Reference
    # * Shrout,P. & Fleiss, J. (1979). Intraclass Correlation: Uses in assessing rater reliability. Psychological Bulletin, 86(2), 420-428
    # * McGraw, K. & Wong, S.P. (1996). Forming Inferences About Some Intraclass Correlation Coefficients. Psychological methods, 1(1), 30-46.

    class ICC
      include Summarizable
      
      # Create a ICC analysis for a given dataset
      # Each vector is a different measurement. Only uses complete data 
      # (listwise deletion).
      #
      
      attr_reader :df_bt
      attr_reader :df_wt
      attr_reader :df_bj
      attr_reader :df_residual

      attr_reader :ms_bt
      attr_reader :ms_wt
      attr_reader :ms_bj
      attr_reader :ms_residual

      alias :bms :ms_bt
      alias :wms :ms_wt
      alias :jms :ms_bj
      alias :ems :ms_residual
      
      alias :msr :ms_bt
      alias :msw :ms_wt
      alias :msc :ms_bj
      alias :mse :ms_residual
      
      # :section: Shrout and Fleiss ICC denominations
      attr_reader :icc_1_1
      attr_reader :icc_2_1
      attr_reader :icc_3_1
      attr_reader :icc_1_k
      attr_reader :icc_2_k
      attr_reader :icc_3_k

      # :section: McGraw and Wong ICC denominations
      
      attr_reader :icc_1
      attr_reader :icc_c_1
      attr_reader :icc_a_1
      attr_reader :icc_k
      attr_reader :icc_c_k
      attr_reader :icc_a_k
      
      
      
      
      
      
      attr_reader :n, :k
      
      attr_reader :total_mean
      def initialize(ds, opts=Hash.new)
        @ds=ds.dup_only_valid
        @vectors=@ds.vectors.values
        @n=@ds.cases
        @k=@ds.fields.size
        opts_default={:name=>"Intra-class correlation"}
        @opts=opts_default.merge(opts)
        @opts.each{|k,v| self.send("#{k}=",v) if self.respond_to? k }
        compute
        
      end
      def compute
        @df_bt=n-1
        @df_wt=n*(k-1)
        @df_bj=k-1
        @df_residual=(n-1)*(k-1)
        @total_mean=@vectors.inject(0){|ac,v| ac+v.sum}.quo(n*k)
        vm=@ds.vector_mean
        
        @ss_bt=k*vm.ss(@total_mean)
        @ms_bt=@ss_bt.quo(@df_bt)
        
        @ss_bj=n*@vectors.inject(0){|ac,v| ac+(v.mean-@total_mean).square}
        @ms_bj=@ss_bj.quo(@df_bj)
        
        @ss_wt=@vectors.inject(0){|ac,v| ac+(v-vm).ss(0)}
        @ms_wt=@ss_wt.quo(@df_wt)
        
        @ss_residual=@ss_wt-@ss_bj
        @ms_residual=@ss_residual.quo(@df_residual)
        ###
        # Shrout and Fleiss denomination
        ###
        # ICC(1,1) / ICC(1)
        @icc_1_1=(bms-wms).quo(bms+(k-1)*wms) 
        # ICC(2,1) / ICC(A,1)
        @icc_2_1=(bms-ems).quo(bms+(k-1)*ems+k*(jms - ems).quo(n))  
        # ICC(3,1) / ICC(C,1)
        @icc_3_1=(bms-ems).quo(bms+(k-1)*ems) 
        
        
        
        # ICC(1,K) / ICC(K)
        @icc_1_k=(bms-wms).quo(bms) 
        # ICC(2,K) / ICC(A,k)
        @icc_2_k=(bms-ems).quo(bms+(jms-ems).quo(n))
        # ICC(3,K) / ICC(C,k) = Cronbach's alpha
        @icc_3_k=(bms-ems).quo(bms) 
        
        ###
        # McGraw and Wong
        ###
        
      end
      
      def icc_1_f(rho=0)
        num=msr*(1-rho)
        den=msw*(1+(k-1)*rho)
        Statsample::Test::F.new(num, den, @df_bt, @df_wt)
      end
      # One way random F, type k
      def icc_1_k_f(rho=0)
        num=msr*(1-rho)
        den=msw
        Statsample::Test::F.new(num, den, @df_bt, @df_wt)
      end
      
      def icc_c_1_f(rho=0)
        num=msr*(1-rho)
        den=mse*(1+(k-1)*rho)
        Statsample::Test::F.new(num, den, @df_bt, @df_residual)
      end
      def icc_c_k_f(rho=0)
        num=msr*(1-rho)
        den=msw
        Statsample::Test::F.new(num, den, @df_bt, @df_residual)
      end
      def v(a,b)
        ((a*mcs+b*mse)**2).quo(((a*msc)**2.quo(k-1))+((b*mse)**2.quo((n-1) * (k-1))))
      end
      def a(rho)
        (k*rho).quo(n*(1-rho))
      end
      def b(rho)
        1+(k*rho*(n-1)).quo(n*(1-rho))
      end
      def c(rho)
        rho.quo(n*(1-rho))
      end
      def d(rho)
        1+((rho*(n-1)).quo(n*(1-rho)))
      end
      
      def icc_a_1_f(rho=0)
        num=msr
        den=a*msc+b*mse
        Statsample::Test::F.new(num, den, @df_bt,v(a(rho),b(rho)))        
      end
      def icc_a_k_f(rho=0)
        num=msr
        den=c*msc+d*mse
        Statsample::Test::F.new(num, den, @df_bt,v(c(rho),d(rho)))        

      end
      
      # F test for ICC Case 1. Shrout and Fleiss
      def icc_1_f_shrout
        Statsample::Test::F.new(bms, wms, @df_bt, @df_wt)
      end

      # Intervale of confidence for ICC (1,1)
      def icc_1_1_ci(alpha=0.05)
        per=1-(0.5*alpha)
       
        fu=icc_1_f.f*Distribution::F.p_value(per, @df_wt, @df_bt)
        fl=icc_1_f.f.quo(Distribution::F.p_value(per, @df_bt, @df_wt))
        
        [(fl-1).quo(fl+k-1), (fu-1).quo(fu+k-1)]
      end
      # Intervale of confidence for ICC (1,k)
      def icc_1_k_ci(alpha=0.05)
        per=1-(0.5*alpha)
        fu=icc_1_f.f*Distribution::F.p_value(per, @df_wt, @df_bt)
        fl=icc_1_f.f.quo(Distribution::F.p_value(per, @df_bt, @df_wt))
        [1-1.quo(fl), 1-1.quo(fu)]
      end
      
      # F test for ICC Case 2
      def icc_2_f
        Statsample::Test::F.new(bms, ems, @df_bt, @df_residual)
      end
      
      
      #
      # F* for ICC(2,1) and ICC(2,k)
      # 
      def icc_2_1_fs(pp,alpha=0.05)
        fj=jms.quo(ems)
        per=1-(0.5*alpha)
        vn=(k-1)*(n-1)*((k*pp*fj+n*(1+(k-1)*pp)-k*pp)**2)
        vd=(n-1)*(k**2)*(pp**2)*(fj**2)+((n*(1+(k-1)*pp)-k*pp)**2)
        v=vn.quo(vd)
        f1=Distribution::F.p_value(per, n-1,v)
        f2=Distribution::F.p_value(per, v, n-1)
        [f1,f2]
      end
     
      
      def icc_2_1_ci(alpha=0.05)
        icc_2_1_ci_mcgraw
      end
      
      # Confidence interval ICC(A,1), McGawn
      
      def icc_2_1_ci_mcgraw(alpha=0.05)
        fd,fu=icc_2_1_fs(icc_2_1,alpha)
        cl=(n*(msr-fd*mse)).quo(fd*(k*msc+(k*n-k-n)*mse)+n*msr)
        cu=(n*(fu*msr-mse)).quo(k*msc+(k*n-k-n)*mse+n*fu*msr)
        [cl,cu]
      end
      
      def icc_2_k_ci(alpha=0.05)
        icc_2_k_ci_mcgraw(alpha)
      end
      
      def icc_2_k_ci_mcgraw(alpha=0.05)
        f1,f2=icc_2_1_fs(icc_2_k,alpha)
        [
        (n*(msr-f1*mse)).quo(f1*(msc-mse)+n*msr),
        (n*(f2*msr-mse)).quo(msc-mse+n*f2*msr)
        ]
        
      end
      def icc_2_k_ci_shrout(alpha=0.05)
        ci=icc_2_1_ci(alpha)
        [(ci[0]*k).quo(1+(k-1)*ci[0]), (ci[1]*k).quo(1+(k-1)*ci[1])]
      end
      
      
      def icc_3_f
        Statsample::Test::F.new(bms, ems, @df_bt, @df_residual)
      end
      
      def icc_3_1_ci(alpha=0.05)
        per=1-(0.5*alpha)
        fl=icc_3_f.f.quo(Distribution::F.p_value(per, @df_bt, @df_residual))
        fu=icc_3_f.f*Distribution::F.p_value(per, @df_residual, @df_bt)
        [(fl-1).quo(fl+k-1), (fu-1).quo(fu+k-1)]
      end
      def icc_3_k_ci(alpha=0.05)
        per=1-(0.5*alpha)
        fl=icc_3_f.f.quo(Distribution::F.p_value(per, @df_bt, @df_residual))
        fu=icc_3_f.f*Distribution::F.p_value(per, @df_residual, @df_bt)
        [1-1.quo(fl),1-1.quo(fu)]
      end
    end
  end
end
