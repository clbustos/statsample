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
    context Statsample::Reliability::ItemAnalysis do
      setup do 
        @x1=[1,1,1,1,2,2,2,2,3,3,3,30].to_vector(:scale)
        @x2=[1,1,1,2,2,3,3,3,3,4,4,50].to_vector(:scale)
        @x3=[2,2,1,1,1,2,2,2,3,4,5,40].to_vector(:scale)
        @x4=[1,2,3,4,4,4,4,3,4,4,5,30].to_vector(:scale)
        @ds={'x1'=>@x1,'x2'=>@x2,'x3'=>@x3,'x4'=>@x4}.to_dataset
        @ia=Statsample::Reliability::ItemAnalysis.new(@ds)

      end     
      should "return correct values for item analysis" do 
        assert_in_delta(0.980,@ia.alpha,0.001)
        assert_in_delta(0.999,@ia.alpha_standarized,0.001)
        assert_in_delta(0.999,@ia.item_total_correlation()['x1'],0.001)
        assert_in_delta(1050.455,@ia.stats_if_deleted()['x1'][:variance_sample],0.001)
      end
      should "return a summary" do 
        assert(@ia.summary.size>0)
      end
      
    end
  end
end
