module Statsample
  module Reliability
    # DSL for analysis of multiple scales analysis. Analoge of Scale Reliability analysis on SPSS.
    # Returns several statistics for complete scale and each item
    # == Usage
    #  @x1=[1,1,1,1,2,2,2,2,3,3,3,30].to_vector(:scale)
    #  @x2=[1,1,1,2,2,3,3,3,3,4,4,50].to_vector(:scale)
    #  @x3=[2,2,1,1,1,2,2,2,3,4,5,40].to_vector(:scale)
    #  @x4=[1,2,3,4,4,4,4,3,4,4,5,30].to_vector(:scale)
    #  ds={'x1'=>@x1,'x2'=>@x2,'x3'=>@x3,'x4'=>@x4}.to_dataset
    #  msa=Statsample::Reliability::MultiScaleAnalysis.new(ds) do |m|
    #    m.scale :s1, "Section 1", %w{x1 x2}
    #    m.scale :s2, "Section 2", %w{x3 x4}
    #    m.correlation_matrix
    #    m.factor_analysis
    #  end
    #  puts msa.summary
    class MultiScaleAnalysis
      def initialize(ds, &block)
        @ds=ds
        @scales=Hash.new
        if block
          block.arity<1 ? instance_eval(&block) : block.call(self)
        end
      end
      # Returns a ScaleAnalysis of full scale
      def complete_scale
        ScaleAnalysis.new(@ds, :name=>"Complete Scale")
      end
      def scale(code,opts=nil,fields=nil)
        if fields.nil?
          @scales[code]
        else
          opts={:name=>"Scale #{code}"} if opts.nil?
          @scales[code]=ScaleAnalysis.new(@ds.dup(fields), opts)
        end
      end
      def correlation_matrix
        vectors=Hash.new
        @scales.each_pair do |code,scale|
          vectors[code.to_s]=scale.ds.vector_sum
        end
        Statsample::Bivariate.correlation_matrix(vectors.to_dataset)
      end
    end
  end
end