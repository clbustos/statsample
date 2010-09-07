module Statsample
  module Factor
    # Performs Horn's 'parallel analysis' to a principal components analysis
    # to adjust for sample bias in the retention of components. 
    # Can create the bootstrap samples using random data, using number
    # of cases and variables, parameters for actual data (mean and standard
    # deviation of each variable) or bootstrap sampling for actual data.
    # == Description
    # "PA involves the construction of a number of correlation matrices of random variables based on the same sample size and number of variables in the real data set. The average eigenvalues from the random correlation matrices are then compared to the eigenvalues from the real data correlation matrix, such that the first observed eigenvalue is compared to the first random eigenvalue, the second observed eigenvalue is compared to the second random eigenvalue, and so on." (Hayton, Allen & Scarpello, 2004, p.194)
    # == Usage
    # *With real dataset*
    #   # ds should be any valid dataset
    #   pa=Statsample::Factor::ParallelAnalysis.new(ds, :iterations=>100, :bootstrap_method=>:raw_data)
    #
    # *With number of cases and variables*
    #   pa=Statsample::Factor::ParallelAnalysis.with_random_data(100,8)
    # 
    # == Reference:
    # * Hayton, J., Allen, D. & Scarpello, V.(2004). Factor Retention Decisions in Exploratory Factor Analysis: a Tutorial on Parallel Analysis. <i>Organizational Research Methods, 7</i> (2), 191-205.
    # * O'Connor, B. (2000). SPSS and SAS programs for determining the number of components using parallel analysis and Velicer's MAP test. Behavior Research Methods, Instruments, & Computers, 32(3), 396-402.
    # * Liu, O., & Rijmen, F. (2008). A modified procedure for parallel analysis of ordered categorical data. Behavior Research Methods, 40(2), 556-562.

    class ParallelAnalysis
      def self.with_random_data(cases,vars,opts=Hash.new)
        require 'ostruct'
        ds=OpenStruct.new
        ds.fields=vars.times.map {|i| "v#{i+1}"}
        ds.cases=cases
        opts=opts.merge({:bootstrap_method=> :random, :no_data=>true})
        pa=new(ds, opts)
      end
      include DirtyMemoize
      include Summarizable
      # Number of random sets to produce. 50 by default
      attr_accessor :iterations
      # Name of analysis
      attr_accessor :name
      # Dataset. You could use mock vectors when use bootstrap method
      attr_reader :ds
      # Bootstrap method. <tt>:random</tt> used by default
      # * <tt>:random</tt>: uses number of variables and cases for the dataset
      # * <tt>:data</tt> : sample with replacement from actual data.       

      attr_accessor :bootstrap_method
      # Uses smc on diagonal of matrixes, to perform simulation
      # of a Principal Axis analysis.
      # By default, false.

      attr_accessor :smc

      # Percentil over bootstrap eigenvalue should be accepted. 95 by default
      attr_accessor :percentil
      # Correlation matrix used with :raw_data . <tt>:correlation_matrix</tt> used by default
      attr_accessor :matrix_method
      # Number of eigenvalues to calculate. Should be set for 
      # Principal Axis Analysis.
      attr_accessor :n_variables
      # Dataset with bootstrapped eigenvalues
      attr_reader :ds_eigenvalues
      # Perform analysis without actual data. 
      attr_accessor :no_data
      # Show extra information if true
      attr_accessor :debug

      def initialize(ds, opts=Hash.new)
        @ds=ds
        @fields=@ds.fields
        @n_variables=@fields.size
        @n_cases=ds.cases
        opts_default={
          :name=>_("Parallel Analysis"),
          :iterations=>50, # See Liu and Rijmen (2008)
          :bootstrap_method => :random,
          :smc=>false,
          :percentil=>95, 
          :debug=>false,
          :no_data=>false,
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
          if (@original[i]>0 and @original[i]>ds_eigenvalues[f].percentil(percentil))
            total+=1
          else
            break
          end
        end
        total
      end
      def report_building(g) #:nodoc:
        g.section(:name=>@name) do |s|
          s.text _("Bootstrap Method: %s") % bootstrap_method
          s.text _("Uses SMC: %s") % (smc ? _("Yes") : _("No"))
          s.text _("Correlation Matrix type : %s") % matrix_method
          s.text _("Number of variables: %d") % @n_variables
          s.text _("Number of cases: %d") % @n_cases
          s.text _("Number of iterations: %d") % @iterations
          if @no_data
            s.table(:name=>_("Eigenvalues"), :header=>[_("n"), _("generated eigenvalue"), "p.#{percentil}"]) do |t|
              ds_eigenvalues.fields.each_with_index do |f,i|
                v=ds_eigenvalues[f]
                t.row [i+1, "%0.4f" %  v.mean, "%0.4f" %  v.percentil(percentil), ]
              end
            end
          else
            s.text _("Number or factors to preserve: %d") % number_of_factors 
            s.table(:name=>_("Eigenvalues"), :header=>[_("n"), _("data eigenvalue"), _("generated eigenvalue"),"p.#{percentil}",_("preserve?")]) do |t|
              ds_eigenvalues.fields.each_with_index do |f,i|
                v=ds_eigenvalues[f]
                t.row [i+1, "%0.4f" % @original[i], "%0.4f" %  v.mean, "%0.4f" %  v.percentil(percentil), (v.percentil(percentil)>0 and @original[i] > v.percentil(percentil)) ? "Yes":""]
              end
            end
          end
          
        end
      end
      # Perform calculation. Shouldn't be called directly for the user
      def compute
        
        @original=Statsample::Bivariate.send(matrix_method, @ds).eigenvalues unless no_data        
        @ds_eigenvalues=Statsample::Dataset.new((1..@n_variables).map{|v| "ev_%05d" % v})
        @ds_eigenvalues.fields.each {|f| @ds_eigenvalues[f].type=:scale}
        if bootstrap_method==:parameter or bootstrap_method==:random
          rng = GSL::Rng.alloc(GSL::Rng::MT19937, rand(32000))
        end
        
        @iterations.times do |i|
          begin
            puts "#{@name}: Iteration #{i}" if $DEBUG or debug
            # Create a dataset of dummy values
            ds_bootstrap=Statsample::Dataset.new(@ds.fields)
            @fields.each do |f|
              if bootstrap_method==:random
                ds_bootstrap[f]=@n_cases.times.map {|c| rng.ugaussian()}.to_scale
              elsif bootstrap_method==:data
                ds_bootstrap[f]=ds[f].sample_with_replacement(@n_cases).to_scale
              else
                raise "bootstrap_method doesn't recogniced"
              end
            end
            matrix=Statsample::Bivariate.send(matrix_method, ds_bootstrap)
            if smc
                smc_v=matrix.inverse.diagonal.map{|ii| 1-(1.quo(ii))}
                smc_v.each_with_index do |v,ii| 
                  matrix[ii,ii]=v
                end
            end
            ev=matrix.eigenvalues
            @ds_eigenvalues.add_case_array(ev)
          rescue Tetrachoric::RequerimentNotMeet => e
            puts "Error: #{e}" if $DEBUG
            redo
          end
        end
        @ds_eigenvalues.update_valid_data
      end
      dirty_memoize :number_of_factors, :ds_eigenvalues
      dirty_writer :iterations, :bootstrap_method, :percentil, :smc
    end
  end
end
