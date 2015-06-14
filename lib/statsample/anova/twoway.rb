module Statsample
  module Anova
    # = Generic Anova two-way.
    # You could enter the sum of squares or the mean squares for a, b, axb and within. 
    # You should enter the degrees of freedom for a,b and within, because df_axb=df_a*df_b
    # == Usage
    #  anova=Statsample::Anova::TwoWay(:ss_a=>10,:ss_b=>20,:ss_axb=>10, :ss_within=>20, :df_a=>2, :df_b=>3,df_within=100 @name=>"ANOVA for....")
    class TwoWay
      include Summarizable
      attr_reader :df_a, :df_b, :df_axb, :df_within, :df_total
      attr_reader :ss_a, :ss_b, :ss_axb, :ss_within, :ss_total
      attr_reader :ms_a, :ms_b, :ms_axb, :ms_within, :ms_total
      # Name of ANOVA Analisys
      attr_accessor :name
      # Name of a factor
      attr_accessor :name_a
      # Name of b factor
      attr_accessor :name_b
      # Name of within factor
      attr_accessor :name_within
      
      attr_reader :f_a_object, :f_b_object, :f_axb_object
      def initialize(opts=Hash.new)
        # First see if sum of squares or mean squares are entered
        raise ArgumentError, "You should set all d.f." unless [:df_a, :df_b, :df_within].all? {|v| opts.has_key? v}
        
        @df_a=opts.delete :df_a
        @df_b=opts.delete :df_b
        @df_axb=@df_a*@df_b
        @df_within=opts.delete :df_within
        @df_total=@df_a+@df_b+@df_axb+@df_within
        
        if [:ss_a, :ss_b, :ss_axb, :ss_within].all? {|v| opts.has_key? v}
          @ss_a = opts.delete :ss_a
          @ss_b = opts.delete :ss_b
          @ss_axb = opts.delete :ss_axb
          @ss_within = opts.delete :ss_within
          
          @ms_a =@ss_a.quo(@df_a)
          @ms_b =@ss_b.quo(@df_b) 
          @ms_axb =@ss_axb.quo(@df_axb)
          @ms_within =@ss_within.quo(@df_within) 

        elsif [:ms_a, :ms_b, :ms_axb, :ms_within].all? {|v| opts.has_key? v}
          @ms_a = opts.delete :ms_a
          @ms_b = opts.delete :ms_b
          @ms_axb = opts.delete :ms_axb
          @ms_within = opts.delete :ms_within
          
          @ss_a =@ms_a*@df_a
          @ss_b =@ms_b*@df_b 
          @ss_axb =@ms_axb*@df_axb
          @ss_within =@ms_within*@df_within
        else
          raise "You should set all ss or ss"
        end
        @ss_total=@ss_a+@ss_b+@ss_axb+@ss_within
        @ms_total=@ms_a+@ms_b+@ms_axb+@ms_within
        opts_default={:name=>_("ANOVA Two-Way"),
                      :name_a=>_("A"),
                      :name_b=>_("B"),
                      :name_within=>_("Within")                      
        }
        @opts=opts_default.merge(opts)
        opts_default.keys.each {|k|
          send("#{k}=", @opts[k])
        }
        @f_a_object=Statsample::Test::F.new(@ms_a,@ms_within,@df_a,@df_within)
        @f_b_object=Statsample::Test::F.new(@ms_b,@ms_within,@df_b,@df_within)
        @f_axb_object=Statsample::Test::F.new(@ms_axb,@ms_within,@df_axb,@df_within)
      end
      def f_a
        @f_a_object.f
      end
      def f_b
        @f_b_object.f
      end
      def f_axb
        @f_axb_object.f
      end
      def f_a_probability
        @f_a_object.probability
      end
      def f_b_probability
        @f_b_object.probability
      end
      def f_axb_probability
        @f_axb_object.probability
      end
            

      def report_building(builder) #:nodoc:
        builder.section(:name=>@name) do |b|
          report_building_table(b)
        end
      end
      def report_building_table(builder) #:nodoc:
        builder.table(:name=>_("%s Table") % @name, :header=>%w{source ss df ms f p}.map {|v| _(v)}) do |t|
          t.row([@name_a, "%0.3f" % @ss_a,   @df_a, "%0.3f" % @ms_a , "%0.3f" % f_a, "%0.4f" % f_a_probability] )
          t.row([@name_b, "%0.3f" % @ss_b,   @df_b, "%0.3f" % @ms_b , "%0.3f" % f_b, "%0.4f" % f_b_probability] )
          t.row(["%s X %s" % [@name_a, @name_b], "%0.3f" % @ss_axb,   @df_axb, "%0.3f" % @ms_axb , "%0.3f" % f_axb, "%0.4f" % f_axb_probability] )          
          t.row([@name_within, "%0.3f" % @ss_within,   @df_within, nil,nil,nil] )
          t.row([_("Total"), "%0.3f" % @ss_total,   @df_total, nil,nil,nil] )          
        end
      end
    end
    
    # Two Way Anova with vectors
    # Example:
    #   v1 = Daru::Vector.new([1,1,2,2])
    #   v2 = Daru::Vector.new([1,2,1,2])
    #   v3 = Daru::Vector.new([5,3,1,5])
    #   anova=Statsample::Anova::TwoWayWithVectors.new(:a=>v1,:b=>v2, :dependent=>v3)
    #
    class TwoWayWithVectors < TwoWay
       # Show summary Levene test
      attr_accessor :summary_levene
      # Show summary descriptives for variables (means)
      attr_accessor :summary_descriptives
      attr_reader :a_var, :b_var, :dep_var
      # For now, only equal sample cells allowed
      def initialize(opts=Hash.new)
        raise "You should insert at least :a, :b and :dependent" unless  [:a, :b, :dependent].all? {|v| opts.has_key? v}
        @a_var   = :a
        @b_var   = :b
        @dep_var = :dependent
        @a_vector, @b_vector, @dep_vector = 
          Statsample.only_valid_clone opts[:a], opts[:b], opts[:dependent]
        
        ds  = Daru::DataFrame.new({@a_var=>@a_vector, @b_var=>@b_vector, @dep_var=>@dep_vector})
        @ds = ds.clone_only_valid
        _p  = @a_vector.factors.size
        _q  = @b_vector.factors.size
        @x_general = @dep_vector.mean
        @axb_means = {}
        @axb_sd    = {}
        @vectors   = []
        n=nil
        @ds.to_multiset_by_split(a_var,b_var).each_vector(dep_var) {|k,v|
          @axb_means[k] = v.mean
          @axb_sd[k]    = v.sd
          @vectors << v
          n ||= v.size
          raise "All cell sizes should be equal" if n!=v.size
        }

        @a_means={}
        @ds.to_multiset_by_split(a_var).each_vector(dep_var) {|k,v|
          @a_means[k]=v.mean
        }
        @b_means={}
        @ds.to_multiset_by_split(b_var).each_vector(dep_var) {|k,v|
          @b_means[k]=v.mean
        }
        ss_a = n*_q*@ds[a_var].factors.inject(0) {|ac,v|
          ac + (@a_means[v]-@x_general)**2
        }
        ss_b=n*_p*@ds[b_var].factors.inject(0) {|ac,v|
          ac+(@b_means[v]-@x_general)**2
        }
        ss_within = @ds.collect(:row) { |row|
          (row[dep_var]-@axb_means[[row[a_var],row[b_var]]])**2
        }.sum
        ss_axb = n*@axb_means.inject(0) {|ac,v|
          j,k=v[0]
          xjk=v[1]
          ac+(xjk-@a_means[j]-@b_means[k]+@x_general)**2
        }

        df_a=_p-1
        df_b=_q-1
        df_within=(_p*_q)*(n-1)
        
        opts_default={:name=>_("Anova Two-Way on %s") % @ds[dep_var].name, 
          :name_a=>@ds[a_var].name,
            :name_b=>@ds[b_var].name,
            :summary_descriptives=>true,
            :summary_levene=>false}
            
        @opts=opts_default.merge(opts).merge({:ss_a=>ss_a,:ss_b=>ss_b, :ss_axb=>ss_axb, :ss_within=>ss_within, :df_a=>df_a, :df_b=>df_b, :df_within=>df_within})
        
        
        super(@opts)
      end
      def levene
        Statsample::Test.levene(@vectors, :name=>_("Test of Homogeneity of variances (Levene)"))
      end      
      def report_building(builder) #:nodoc:#
        builder.section(:name=>@name) do |s|
          if summary_descriptives
            s.table(:header =>['']+@ds[a_var].factors.map {|a| @ds[a_var].index_of(a)}+[_("%s Mean") % @name_b]) do |t|
              @ds[b_var].factors.each do |b|
                t.row([@ds[b_var].index_of(b)]+@ds[a_var].factors.map {|a| "%0.3f" % @axb_means[[a,b]] } + ["%0.3f" % @b_means[b]])
              end
              t.row([_("%s Mean") % @name_a]+@ds[a_var].factors.map {|a| "%0.3f" % @a_means[a]}+ ["%0.3f" % @x_general])
            end
          end
          if summary_levene
            s.parse_element(levene)
          end
          report_building_table(s)

        end
      end
    end
  end
end
