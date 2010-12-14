module Statsample
  module Reliability
    # Analysis of a Skill Scale
    # Given a dataset with results and a correct answers hash,
    # generates a ScaleAnalysis 
    # == Usage
    #  x1=%{a b b c}.to_vector
    #  x2=%{b a b c}.to_vector
    #  x3=%{a c b a}.to_vector
    #  ds={'x1'=>@x1,'x2'=>@x2,'x3'=>@x3}.to_dataset
    #  key={'x1'=>'a','x2'=>'b','x3'=>'a'}    
    #  ssa=Statsample::Reliability::SkillScaleAnalysis.new(ds,key)
    #  puts ssa.summary
    class SkillScaleAnalysis
      include Summarizable
      attr_accessor :name
      attr_accessor :summary_minimal_item_correlation
      attr_accessor :summary_show_problematic_items
      def initialize(ds,key,opts=Hash.new)
        opts_default={
          :name=>_("Skill Scale Reliability Analysis (%s)") % ds.name,
          :summary_minimal_item_correlation=>0.10,
          :summary_show_problematic_items=>true
        }
        @ds=ds
        @key=key
        @opts=opts_default.merge(opts)
        @opts.each{|k,v| self.send("#{k}=",v) if self.respond_to? k }
        @cds=nil
      end
      def corrected_dataset_minimal
        cds=corrected_dataset
        dsm=@key.keys.inject({}) {|ac,v| ac[v]=cds[v];ac}.to_dataset
        @key.keys.each do |k|
          dsm[k].name=_("%s(corrected)") % @ds[k].name
          dsm[k].labels=@ds[k].labels
        end
        
        dsm.name=_("Corrected dataset from %s") % @ds.name
        dsm
      end
      def vector_sum
        corrected_dataset_minimal.vector_sum
      end
      def vector_mean
        corrected_dataset_minimal.vector_mean
      end
      def scale_analysis
        sa=ScaleAnalysis.new(corrected_dataset_minimal)
        sa.name=_("%s (Scale Analysis)") % @name
        sa
      end
      def corrected_dataset
        if @cds.nil?
          @cds=@ds.dup_empty
          @key.keys.each {|k| @cds[k].type=:scale; @cds[k].name=@ds[k].name}
          @ds.each do |row|
            out={}
            row.each do |k,v|
              if @key.keys.include? k
                if @ds[k].is_valid? v
                  out[k]= @key[k]==v ? 1 : 0
                else
                  out[k]=nil
                end
              else
                out[k]=v
              end
            end
            @cds.add_case(out,false)
          end
          @cds.update_valid_data
        end
        @cds
      end
      def report_building(builder)
        builder.section(:name=>@name) do |s|
          sa=scale_analysis
          s.parse_element(sa)
          if summary_show_problematic_items
            s.section(:name=>_("Problematic Items")) do |spi|
              count=0
              sa.item_total_correlation.each do |k,v|
                if v < summary_minimal_item_correlation
                  count+=1
                  spi.section(:name=>_("Item: %s") % @ds[k].name) do |spii|
                    spii.text _("Correct answer: %s") % @key[k]
                    spii.text _("p: %0.3f") % corrected_dataset[k].mean
                    props=@ds[k].proportions.inject({}) {|ac,v| ac[v[0]] = v[1].to_f;ac}
                    
                    spi.table(:name=>"Proportions",:header=>[_("Value"), _("%")]) do |table|
                      props.each do |k1,v|
                        table.row [ @ds[k].labeling(k1), "%0.3f" % v]
                      end
                    end
                    
                  end
                end
              end
              spi.text _("No problematic items") if count==0
            end
          end
          
        end
      end
    end    
  end
end
