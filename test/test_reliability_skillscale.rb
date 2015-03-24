require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))


class StatsampleReliabilitySkillScaleTestCase < Minitest::Test
  context Statsample::Reliability::SkillScaleAnalysis do
    setup do
      options=%w{a b c d e}
      cases=20
      @id=cases.times.map {|v| v}.to_scale
      @a=cases.times.map {options[rand(5)]}.to_vector
      @b=cases.times.map {options[rand(5)]}.to_vector
      @c=cases.times.map {options[rand(5)]}.to_vector
      @d=cases.times.map {options[rand(5)]}.to_vector
      @e=cases.times.map {|i|
        i==0 ? options[rand(0)] :
          rand()>0.8 ? nil : options[rand(5)]
      }.to_vector
      @ds={'id'=>@id,'a'=>@a,'b'=>@b,'c'=>@c,'d'=>@d,'e'=>@e}.to_dataset
      @key={'a'=>"a", 'b'=>options[rand(5)], 'c'=>options[rand(5)], 'd'=>options[rand(5)],'e'=>options[rand(5)]}
      @ssa=Statsample::Reliability::SkillScaleAnalysis.new(@ds, @key)
      @ac=@a.map {|v| v==@key['a'] ? 1 : 0}.to_scale
      @bc=@b.map {|v| v==@key['b'] ? 1 : 0}.to_scale
      @cc=@c.map {|v| v==@key['c'] ? 1 : 0}.to_scale
      @dc=@d.map {|v| v==@key['d'] ? 1 : 0}.to_scale
      @ec=@e.map {|v| v.nil? ? nil : (v==@key['e'] ? 1 : 0)}.to_scale

    end
    should "return proper corrected dataset" do
      cds={'id'=>@id, 'a'=>@ac,'b'=>@bc,'c'=>@cc,'d'=>@dc, 'e'=>@ec}.to_dataset
      assert_equal(cds, @ssa.corrected_dataset)
    end
    should "return proper corrected minimal dataset" do
      cdsm={'a'=>@ac,'b'=>@bc,'c'=>@cc,'d'=>@dc, 'e'=>@ec}.to_dataset
      assert_equal(cdsm, @ssa.corrected_dataset_minimal)
    end
    should "return correct vector_sum and vector_sum" do
      cdsm=@ssa.corrected_dataset_minimal
      assert_equal(cdsm.vector_sum, @ssa.vector_sum)
      assert_equal(cdsm.vector_mean, @ssa.vector_mean)
    end
    should "not crash on rare case" do
      a=Statsample::Vector["c","c","a","a","c","a","b","c","c","b","a","d","a","d","a","a","d","e","c","d"]
      b=Statsample::Vector["e","b","e","b","c","d","a","e","e","c","b","e","e","b","d","c","e","b","b","d"]
      c=Statsample::Vector["e","b","e","c","e","c","b","d","e","c","a","a","b","d","e","c","b","a","a","e"]
      d=Statsample::Vector["a","b","d","d","e","b","e","b","d","c","e","a","c","d","c","c","e","d","d","b"]
      e=Statsample::Vector["a","b",nil,"d","c","c","d",nil,"d","d","e","e",nil,nil,nil,"d","c",nil,"e","d"]
      key={"a"=>"a", "b"=>"e", "c"=>"d", "d"=>"c", "e"=>"d"}
      ds=Statsample::Dataset.new("a"=>a,"b"=>b,"c"=>c,"d"=>d,"e"=>e)
      ssa=Statsample::Reliability::SkillScaleAnalysis.new(ds, key)
      assert(ssa.summary)
    end

    should "return valid summary" do
      assert(@ssa.summary.size>0)
    end
  end
end
