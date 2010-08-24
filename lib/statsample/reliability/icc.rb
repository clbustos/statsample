module Statsample
  module Reliability
    # = Intra-class correlation
    # According to Shrout & Fleiss (1979, p.422): "ICC is the correlation 
    # between one measurement (either a single rating or a mean of 
    # several ratings) on a target and another measurement obtained on that target"
    # 
    # == Reference
    # * Shrout,P. & Fleiss, J. (1979). Intraclass Correlation: Uses in assessing rater reliability. Psychological Bulletin, 86(2), 420-428
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
      
      attr_reader :icc_1_1
      attr_reader :icc_2_1
      attr_reader :icc_3_1

      attr_reader :icc_1_k
      attr_reader :icc_2_k
      attr_reader :icc_3_k


      
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
        
        # Icc
        
        @icc_1_1=(bms-wms).quo(bms+(k-1)*wms)
        @icc_2_1=(bms-ems).quo(bms+(k-1)*ems + k*(jms-ems).quo(n))
        @icc_3_1=(bms-ems).quo(bms+(k-1)*ems)
        
        @icc_1_k=(bms-wms).quo(bms)
        @icc_2_k=(bms-ems).quo(bms+(jms-ems).quo(n))
        @icc_3_k=(bms-ems).quo(bms)
      end
      # F test for ICC Case 1
      def icc_1_f
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
      
      def icc_2_1_ci(alpha=0.05)
        fj=jms.quo(ems)
        pp=icc_2_1
        per=1-(0.5*alpha)
        vn=(k-1)*(n-1)*(k*pp*fj+n*(1+(k-1)*pp)-k*pp)**2
        vd=(n-1)*(k**2)*(pp**2)*(fj**2)+(n*(1+(k-1)*pp)-k*pp)**2
        v=vn.quo(vd)
        f1=Distribution::F.p_value(per, n-1,v)
        f2=Distribution::F.p_value(per, v, n-1)
        [(n*(bms-f1*ems)).quo(f1*(k*jms+(k*n-k-n)*ems)+n*bms),
         (n*(f2*bms-ems)).quo(k*jms+(k*n-k-n)*ems+n*f2*bms)]
        
      end
      def icc_2_k_ci(alpha=0.05)
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
