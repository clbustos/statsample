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
    #  msa=Statsample::Reliability::MultiScaleAnalysis.new(:name=>"Scales") do |m|
    #    m.scale :s1, "Section 1", ds.clone(%w{x1 x2})
    #    m.scale :s2, "Section 2", ds.clone(%w{x3 x4})
    #    m.correlation_matrix
    #    m.factor_analysis
    #  end
    #  puts msa.summary
    class MultiScaleAnalysis
      include Statsample::Summarizable
      attr_reader :scales
      attr_accessor :name
      attr_accessor :summary_correlation_matrix
      attr_accessor :summary_pca
      attr_accessor :pca_options
      def initialize(opts=Hash.new, &block)
        @scales=Hash.new
        opts_default={  :name=>"Multiple Scale analysis",
                        :summary_correlation_matrix=>false,
                        :summary_pca=>false,
                        :pca_options=>Hash.new}
        @opts=opts_default.merge(opts)
        @opts.each{|k,v|
          self.send("#{k}=",v) if self.respond_to? k
        }

        if block
          block.arity<1 ? instance_eval(&block) : block.call(self)
        end
      end
      def scale(code,ds=nil, opts=nil)
        if ds.nil?
          @scales[code]
        else
          opts={:name=>_("Scale %s") % [code]} if opts.nil?
          @scales[code]=ScaleAnalysis.new(ds, opts)
        end
      end
      def delete_scale(code)
        @scales.delete code
      end
      def pca(opts=Hash.new)
        Statsample::Factor::PCA.new(correlation_matrix,opts)
      end
      def factor_analysis(opts=nil)
        opts||=pca_options
        Statsample::Factor::FactorAnalysis.new(correlation_matrix,opts)
      end
      
      def correlation_matrix
        vectors=Hash.new
        @scales.each_pair do |code,scale|
          vectors[code.to_s]=scale.ds.vector_sum
        end
        Statsample::Bivariate.correlation_matrix(vectors.to_dataset)
      end
      def report_building(b)
        b.section(:name=>name) do |s|
          s.section(:name=>"Reliability analysis of scales") do |s2|
            @scales.each_pair do |k,scale|
              s2.parse_element(scale)
            end
          end
          if summary_correlation_matrix
            s.parse_element(correlation_matrix)
          end
          if summary_pca
            s.parse_element(pca)
          end
        end
      end
    end
  end
end