module Statsample
  module Reliability
    # DSL for analysis of multiple scales analysis. 
    # Retrieves reliability analysis for each scale and
    # provides fast accessors to correlations matrix,
    # PCA and Factor Analysis.
    # 
    # == Usage
    #  @x1 = Daru::Vector.new([1,1,1,1,2,2,2,2,3,3,3,30])
    #  @x2 = Daru::Vector.new([1,1,1,2,2,3,3,3,3,4,4,50])
    #  @x3 = Daru::Vector.new([2,2,1,1,1,2,2,2,3,4,5,40])
    #  @x4 = Daru::Vector.new([1,2,3,4,4,4,4,3,4,4,5,30])
    #  ds  = Daru::DataFrame.new({:x1 => @x1,:x2 => @x2,:x3 => @x3,:x4 => @x4})
    #  opts={:name=>"Scales", # Name of analysis
    #        :summary_correlation_matrix=>true, # Add correlation matrix
    #        :summary_pca } # Add PCA between scales
    #  msa=Statsample::Reliability::MultiScaleAnalysis.new(opts) do |m|
    #    m.scale :s1, ds.clone([:x1, :x2])
    #    m.scale :s2, ds.clone([:x3, :x4]), {:name=>"Scale 2"}
    #  end
    #  # Retrieve summary
    #  puts msa.summary 
    class MultiScaleAnalysis
      include Statsample::Summarizable
      # Hash with scales
      attr_reader :scales
      # Name of analysis
      attr_accessor :name
      # Add a correlation matrix on summary
      attr_accessor :summary_correlation_matrix
      # Add PCA to summary
      attr_accessor :summary_pca
      # Add Principal Axis to summary
      attr_accessor :summary_principal_axis
      # Options for Factor::PCA object
      attr_accessor :pca_options
      # Options for Factor::PrincipalAxis 
      attr_accessor :principal_axis_options
      
      # Add Parallel Analysis to summary
      attr_accessor :summary_parallel_analysis
      # Options for Parallel Analysis
      attr_accessor :parallel_analysis_options
      
      # Add MPA to summary
      attr_accessor :summary_map
      # Options for MAP
      attr_accessor :map_options
      
      
      # Generates a new MultiScaleAnalysis
      # Opts could be any accessor of the class 
      # * :name, 
      # * :summary_correlation_matrix
      # * :summary_pca
      # * :summary_principal_axis
      # * :summary_map
      # * :pca_options
      # * :factor_analysis_options
      # * :map_options
      # If block given, all methods should be called
      # inside object environment.
      # 
      def initialize(opts=Hash.new, &block)
        @scales=Hash.new
        @scales_keys=Array.new
        opts_default={  :name=>_("Multiple Scale analysis"),
                        :summary_correlation_matrix=>false,
                        :summary_pca=>false,
                        :summary_principal_axis=>false,
                        :summary_parallel_analysis=>false,
                        :summary_map=>false,
                        :pca_options=>Hash.new,
                        :principal_axis_options=>Hash.new,
                        :parallel_analysis_options=>Hash.new,
                        :map_options=>Hash.new
        }
        @opts=opts_default.merge(opts)
        @opts.each{|k,v|
          self.send("#{k}=",v) if self.respond_to? k
        }

        if block
          block.arity<1 ? instance_eval(&block) : block.call(self)
        end
      end
      # Add or retrieve a scale to analysis.
      # If second parameters is a dataset, generates a ScaleAnalysis 
      # for <tt>ds</tt>, named <tt>code</tt> with options <tt>opts</tt>.
      # 
      # If second parameters is empty, returns the ScaleAnalysis
      # <tt>code</tt>.
      def scale(code, ds=nil, opts=nil)
        if ds.nil?
          @scales[code]
        else
          opts={:name=>_("Scale %s") % code} if opts.nil?
          @scales_keys.push(code)
          @scales[code]=ScaleAnalysis.new(ds, opts)
        end
      end
      # Delete ScaleAnalysis named <tt>code</tt>
      def delete_scale(code)
        @scales_keys.delete code
        @scales.delete code
      end
      # Retrieves a Principal Component Analysis (Factor::PCA)
      # using all scales, using <tt>opts</tt> a options.
      def pca(opts=nil)
        opts ||= pca_options        
        Statsample::Factor::PCA.new(correlation_matrix, opts)
      end
      # Retrieve Velicer's MAP
      # using all scales.
      def map(opts=nil)
        opts||=map_options
        Statsample::Factor::MAP.new(correlation_matrix, opts)
      end
      # Retrieves a PrincipalAxis Analysis (Factor::PrincipalAxis)
      # using all scales, using <tt>opts</tt> a options.
      def principal_axis_analysis(opts=nil)
        opts||=principal_axis_options
        Statsample::Factor::PrincipalAxis.new(correlation_matrix, opts)
      end
      def dataset_from_scales
        ds = Daru::DataFrame.new({}, order: @scales_keys.map(&:to_sym))
        @scales.each_pair do |code,scale|
          ds[code.to_sym] = scale.ds.vector_sum
        end
        
        ds.update
        ds
      end

      def parallel_analysis(opts=nil)
        opts||=parallel_analysis_options
        Statsample::Factor::ParallelAnalysis.new(dataset_from_scales, opts)
      end
      # Retrieves a Correlation Matrix between scales.
      # 
      def correlation_matrix
        Statsample::Bivariate.correlation_matrix(dataset_from_scales)
      end

      def report_building(b) # :nodoc:
        b.section(:name=>name) do |s|
          s.section(:name=>_("Reliability analysis of scales")) do |s2|
            @scales.each_pair do |k, scale|
              s2.parse_element(scale)
            end
          end
          if summary_correlation_matrix
            s.section(:name=>_("Correlation matrix for %s") % name) do |s2|
              s2.parse_element(correlation_matrix)
            end
          end
          if summary_pca
            s.section(:name=>_("PCA for %s") % name) do |s2|
              s2.parse_element(pca)
            end
          end
          if summary_principal_axis
            s.section(:name=>_("Principal Axis for %s") % name) do |s2|
              s2.parse_element(principal_axis_analysis)
            end
          end
          
          if summary_parallel_analysis
            s.section(:name=>_("Parallel Analysis for %s") % name) do |s2|
              s2.parse_element(parallel_analysis)
            end
          end 
          if summary_map
            s.section(:name=>_("MAP for %s") % name) do |s2|
              s2.parse_element(map)
            end
          end           
        end
      end
    end
  end
end