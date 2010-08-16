require(File.dirname(__FILE__)+'/helpers_tests.rb')
class StatsampleReliabilityTestCase < MiniTest::Unit::TestCase
  context Statsample::Reliability do
    context "Cronbach's alpha" do 
      setup do
        @samples=40
        @n_variables=rand(10)+2
        @ds=Statsample::Dataset.new()
        base=@samples.times.collect {|a| rand()}.to_scale
        @n_variables.times do |i|
          @ds[i]=base.collect {|v| v+rand()}.to_scale
        end
        
        @ds.update_valid_data
        @k=@ds.fields.size
        @cm=Statsample::Bivariate.covariance_matrix(@ds)
        @dse=@ds.dup
        @dse.fields.each do |f|
          @dse[f]=@dse[f].standarized
        end
        @cme=Statsample::Bivariate.covariance_matrix(@dse)
        @a=Statsample::Reliability.cronbach_alpha(@ds)
        @as=Statsample::Reliability.cronbach_alpha_standarized(@ds)
      end
      should "alpha will be equal to sum of matrix covariance less the individual variances" do
        total_sum=@cm.total_sum
        ind_var=@ds.fields.inject(0) {|ac,v| ac+@ds[v].variance}
        expected = @k.quo(@k-1) * (1-(ind_var.quo(total_sum)))
        assert_in_delta(expected, @a,1e-10)
      end
      should "method cronbach_alpha_from_n_s2_cov return correct values" do
        sa=Statsample::Reliability::ScaleAnalysis.new(@ds)
        vm, cm = sa.variances_mean, sa.covariances_mean
        assert_in_delta(sa.alpha, Statsample::Reliability.cronbach_alpha_from_n_s2_cov(@n_variables, vm,cm), 1e-10)        
      end
      should "method cronbach_alpha_from_covariance_matrix returns correct value" do
        cov=Statsample::Bivariate.covariance_matrix(@ds)
        assert_in_delta(@a, Statsample::Reliability.cronbach_alpha_from_covariance_matrix(cov),0.0000001)
      end
      should "return correct n for desired alpha, covariance and variance" do
        sa=Statsample::Reliability::ScaleAnalysis.new(@ds)
        vm, cm = sa.variances_mean, sa.covariances_mean
        n_obtained=Statsample::Reliability.n_for_desired_alpha(@a, vm,cm)
        #p n_obtained
        assert_in_delta(Statsample::Reliability.cronbach_alpha_from_n_s2_cov(n_obtained, vm,cm) ,@a,0.001) 
      end
      should "standarized alpha will be equal to sum of matrix covariance less the individual variances on standarized values" do
        total_sum=@cme.total_sum
        ind_var=@dse.fields.inject(0) {|ac,v| ac+@dse[v].variance}
        expected = @k.quo(@k-1) * (1-(ind_var.quo(total_sum)))
        assert_in_delta(expected, @as, 1e-10)
      end
    end
    context Statsample::Reliability::ItemCharacteristicCurve do
      setup do
        @samples=100
        @points=rand(10)+3
        @max_point=(@points-1)*3
        @x1=@samples.times.map{rand(@points)}.to_scale
        @x2=@samples.times.map{rand(@points)}.to_scale
        @x3=@samples.times.map{rand(@points)}.to_scale
        @ds={'a'=>@x1,'b'=>@x2,'c'=>@x3}.to_dataset
        @icc=Statsample::Reliability::ItemCharacteristicCurve.new(@ds)
      end
      should "have a correct automatic vector_total" do
        assert_equal(@ds.vector_sum, @icc.vector_total)
      end
      should "have a correct different vector_total" do
        x2=@samples.times.map{rand(10)}.to_scale
        @icc=Statsample::Reliability::ItemCharacteristicCurve.new(@ds,x2)
        assert_equal(x2, @icc.vector_total)
        assert_raises(ArgumentError) do
          inc=(@samples+10).times.map{rand(10)}.to_scale
          @icc=Statsample::Reliability::ItemCharacteristicCurve.new(@ds,inc)          
        end
      end
      should "have 0% for 0 points on maximum value values" do
        max=@icc.curve_field('a',0)[@max_point.to_f]
        max||=0
        assert_in_delta(0, max)
      end
      should "have 0 for max value on minimum value" do
        max=@icc.curve_field('a',@max_point)[0.0]
        max||=0
        assert_in_delta(0, max)
      end
      should "have correct values of % for any value" do
        sum=@icc.vector_total
        total={}
        total_g=sum.frequencies
        index=rand(@points)
        @x1.each_with_index do |v,i|
          total[sum[i]]||=0
          total[sum[i]]+=1 if v==index
        end
        expected=total.each {|k,v|
          total[k]=v.quo(total_g[k])
        }
        assert_equal(expected, @icc.curve_field('a',index))
        
      end
      
    end
    
    context Statsample::Reliability::MultiScaleAnalysis do
      
      setup do
        size=100
        @scales=3
        @items_per_scale=10
        h={}
        @scales.times {|s|
          @items_per_scale.times {|i|
            h["#{s}_#{i}"] = (size.times.map {(s*2)+rand}).to_scale
          }
        }
        @ds=h.to_dataset
        @msa=Statsample::Reliability::MultiScaleAnalysis.new(:name=>'Multiple Analysis') do |m|
          m.scale "complete", @ds
          @scales.times {|s|
            m.scale "scale_#{s}", @ds.clone(@items_per_scale.times.map {|i| "#{s}_#{i}"}), {:name=>"Scale #{s}"}
          }
        end
      end
      should "Retrieve correct ScaleAnalysis for whole scale" do
        sa=Statsample::Reliability::ScaleAnalysis.new(@ds, :name=>"Scale complete") 
        assert_equal(sa.variances_mean, @msa.scale("complete").variances_mean)
      end
      should "Retrieve correct ScaleAnalysis for each scale" do
        @scales.times {|s|
          sa=Statsample::Reliability::ScaleAnalysis.new(@ds.dup(@items_per_scale.times.map {|i| "#{s}_#{i}"}), :name=>"Scale #{s}")
          assert_equal(sa.variances_mean,@msa.scale("scale_#{s}").variances_mean)
        }
      end
      should "retrieve correct correlation matrix for each scale" do
        vectors={'complete' => @ds.vector_sum}
        @scales.times {|s|
         vectors["scale_#{s}"]=@ds.dup(@items_per_scale.times.map {|i| "#{s}_#{i}"}).vector_sum 
        }
        ds2=vectors.to_dataset
        puts Statsample::Bivariate.correlation_matrix(ds2).summary
        puts @msa.correlation_matrix.summary
        assert_equal(Statsample::Bivariate.correlation_matrix(ds2), @msa.correlation_matrix)
      end
      should "delete scale using delete_scale" do
        @msa.delete_scale("complete")
        assert_equal(@msa.scales.keys.sort, @scales.times.map {|s| "scale_#{s}"})
      end
      should "retrieve pca for scales" do
        @msa.delete_scale("complete")
        vectors=Hash.new
        @scales.times {|s|
         vectors["scale_#{s}"]=@ds.dup(@items_per_scale.times.map {|i| "#{s}_#{i}"}).vector_sum 
        }
        ds2=vectors.to_dataset
        cor_matrix=Statsample::Bivariate.correlation_matrix(ds2)
        m=3
        pca=Statsample::Factor::PCA.new(cor_matrix, :m=>m)
        assert_equal(pca.component_matrix, @msa.pca(:m=>m).component_matrix)
      end
      should "retrieve acceptable summary" do
        @msa.delete_scale("scale_0")
        @msa.delete_scale("scale_1")
        @msa.delete_scale("scale_2")
        
        
        #@msa.summary_correlation_matrix=true
        #@msa.summary_pca=true
        
        
        assert(@msa.summary.size>0)
      end
    end
    context Statsample::Reliability::ScaleAnalysis do
      setup do 
        @x1=[1,1,1,1,2,2,2,2,3,3,3,30].to_scale
        @x2=[1,1,1,2,2,3,3,3,3,4,4,50].to_scale
        @x3=[2,2,1,1,1,2,2,2,3,4,5,40].to_scale
        @x4=[1,2,3,4,4,4,4,3,4,4,5,30].to_scale
        @ds={'x1'=>@x1,'x2'=>@x2,'x3'=>@x3,'x4'=>@x4}.to_dataset
        @ia=Statsample::Reliability::ScaleAnalysis.new(@ds)
        @cov_matrix=@ia.cov_m
      end     
      should "return correct values for item analysis" do 
        assert_in_delta(0.980,@ia.alpha,0.001)
        assert_in_delta(0.999,@ia.alpha_standarized,0.001)
        var_mean=4.times.map{|m| @cov_matrix[m,m]}.to_scale.mean 
        assert_in_delta(var_mean, @ia.variances_mean)
        assert_equal(@x1.mean, @ia.item_statistics['x1'][:mean])
        assert_equal(@x4.mean, @ia.item_statistics['x4'][:mean])
        assert_equal(@x1.sds, @ia.item_statistics['x1'][:sds])
        assert_equal(@x4.sds, @ia.item_statistics['x4'][:sds])
        ds2=@ds.clone
        ds2.delete_vector('x1')
        vector_sum=ds2.vector_sum
        assert_equal(vector_sum.mean, @ia.stats_if_deleted['x1'][:mean])
        assert_equal(vector_sum.sds, @ia.stats_if_deleted['x1'][:sds])
        assert_in_delta(vector_sum.variance, @ia.stats_if_deleted['x1'][:variance_sample],1e-10)

        assert_equal(Statsample::Reliability.cronbach_alpha(ds2), @ia.stats_if_deleted['x1'][:alpha])
        
        covariances=[]
        4.times.each {|i|
          4.times.each {|j|
            if i!=j 
              covariances.push(@cov_matrix[i,j])
            end
          }
        }
        assert_in_delta(covariances.to_scale.mean, @ia.covariances_mean)
        assert_in_delta(0.999,@ia.item_total_correlation()['x1'],0.001)
        assert_in_delta(1050.455,@ia.stats_if_deleted()['x1'][:variance_sample],0.001)
      end
      should "return a summary" do 
        assert(@ia.summary.size>0)
      end
      
    end
  end
end
