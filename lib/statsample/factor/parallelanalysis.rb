module Statsample
  module Factor
    # Performs Horn's 'parallel analysis' to a principal components analysis
    # to adjust for sample bias in the retention of components. 
    # Can create the bootstrap samples using parameters (mean and standard
    # deviation of each variable) or sampling for actual data.
    # == Description
    # "PA involves the construction of a number of correlation matrices of random variables based on the same sample size and number of variables in the real data set. The average eigenvalues from the random correlation matrices are then compared to the eigenvalues from the real data correlation matrix, such that the first observed eigenvalue is compared to the first random eigenvalue, the second observed eigenvalue is compared to the second random eigenvalue, and so on." (Hayton, Allen & Scarpello, 2004, p.194)
    # == Usage
    #   # ds should be any valid dataset
    #   pa=Statsample::Factor::ParallelAnalysis.new(ds, :iterations=>100, :bootstrap_method=>:raw_data)
    #
    # == References:
    # * Hayton, J., Allen, D. & Scarpello, V.(2004). Factor Retention Decisions in Exploratory Factor Analysis: a Tutorial on Parallel Analysis. <i>Organizational Research Methods, 7</i> (2), 191-205.
    # * https://people.ok.ubc.ca/brioconn/nfactors/nfactors.html (for inspiration)
    class ParallelAnalysis
      
      include DirtyMemoize
      include Summarizable
      # Number of random sets to produce. 50 by default
      attr_accessor :iterations
      # Name of analysis
      attr_accessor :name
      # Dataset. You could use mock vectors when use bootstrap method
      attr_reader :ds
      # Bootstrap method. <tt>:raw_data</tt> used by default
      # * <tt>:parameter</tt>: uses mean and standard deviation of each variable
      # * <tt>:raw_data</tt> : sample with replacement from actual data. 
      # 
      attr_accessor :bootstrap_method
      # Factor method.
      # Could be Statsample::Factor::PCA or Statsample::Factor::PrincipalAxis.
      # PCA used by default.
      attr_accessor :factor_class
      # Percentil over bootstrap eigenvalue should be accepted. 95 by default
      attr_accessor :percentil
      # Correlation matrix used with :raw_data . <tt>:correlation_matrix</tt> used by default
      attr_accessor :matrix_method 
      # Dataset with bootstrapped eigenvalues
      attr_reader :ds_eigenvalues
      # Show extra information if true
      attr_accessor :debug
      
      
      def initialize(ds, opts=Hash.new)
        @ds=ds
        @fields=@ds.fields
        @n_variables=@fields.size
        @n_cases=ds.cases
        opts_default={
          :name=>_("Parallel Analysis"),
          :iterations=>50,
          :bootstrap_method => :raw_data,
          :factor_class => Statsample::Factor::PCA,
          :percentil=>95, 
          :debug=>false,
          :matrix_method=>:correlation_matrix
        }
        @opts=opts_default.merge(opts)
        @opts[:matrix_method]==:correlation_matrix if @opts[:bootstrap_method]==:parameters
        opts_default.keys.each {|k| send("#{k}=", @opts[k]) }
      end
      # Number of factor to retent
      def number_of_factors
        total=0
        ds_eigenvalues.fields.each_with_index do |f,i|
          total+=1 if (@original[i]>0 and @original[i]>ds_eigenvalues[f].percentil(percentil))
        end
        total
      end
      def report_building(g) #:nodoc:
        g.section(:name=>@name) do |s|
          s.text _("Bootstrap Method: %s") % bootstrap_method
          s.text _("Correlation Matrix type : %s") % matrix_method
          s.text _("Number of variables: %d") % @n_variables
          s.text _("Number of cases: %d") % @n_cases
          s.text _("Number of iterations: %d") % @iterations
          s.text _("Number or factors to preserve: %d") % number_of_factors
          s.table(:name=>_("Eigenvalues"), :header=>[_("n"), _("data eigenvalue"), _("generated eigenvalue"),"p.#{percentil}",_("preserve?")]) do |t|
            ds_eigenvalues.fields.each_with_index do |f,i|
              v=ds_eigenvalues[f]
              t.row [i+1, "%0.4f" % @original[i], "%0.4f" %  v.mean, "%0.4f" %  v.percentil(percentil), (v.percentil(percentil)>0 and @original[i] > v.percentil(percentil)) ? "Yes":""]
            end
          end
          
        end
      end
      # Perform calculation. Shouldn't be called directly for the user
      def compute
        @original=factor_class.new(Statsample::Bivariate.correlation_matrix(@ds), :m=>@n_variables).eigenvalues.sort.reverse
        @ds_eigenvalues=Statsample::Dataset.new((1..@n_variables).map{|v| "ev_%05d" % v})
        @ds_eigenvalues.fields.each {|f| @ds_eigenvalues[f].type=:scale}
        
        @iterations.times do |i|
          # Create a dataset of dummy values
          ds_bootstrap=Statsample::Dataset.new(@ds.fields)
          if bootstrap_method==:parameter
            rng = GSL::Rng.alloc()
          end
          @fields.each do |f|
    
            if bootstrap_method==:parameter
              sd=@ds[f].sd
              mean=@ds[f].mean
              ds_bootstrap[f]=@n_cases.times.map {|c| rng.gaussian(sd)+mean}.to_scale
            elsif bootstrap_method==:raw_data
              ds_bootstrap[f]=ds[f].sample_with_replacement(@n_cases).to_scale
            end
          end
          fa=factor_class.new(Statsample::Bivariate.send(matrix_method, ds_bootstrap), :m=>@n_variables)
          ev=fa.eigenvalues.sort.reverse
          @ds_eigenvalues.add_case_array(ev)
          puts "iteration #{i}" if $DEBUG or debug
        end
        @ds_eigenvalues.update_valid_data
      end
      dirty_memoize :number_of_factors, :ds_eigenvalues
      dirty_writer :iterations, :bootstrap_method, :factor_class, :percentil
    end
  end
end
