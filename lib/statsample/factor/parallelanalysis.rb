module Statsample
module Factor
  # Performs Horn's 'parallel analysis' to a principal components analysis
  # to adjust for sample bias in the retention of components. 
  # Can create the bootstrap using parameters (mean and standard deviation 
  # of each variable) or sampling for actual data.
  # == Usage
  #   # ds should be any valid dataset
  #   pa=Statsample::Factor::ParallelAnalysis.new(ds, :iterations=>100, :bootstrap_method=>:raw_data
class ParallelAnalysis
  
  include DirtyMemoize
  
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
      :name=>"Parallel Analysis",
      :iterations=>50,
      :bootstrap_method => :raw_data,
      :factor_class => Statsample::Factor::PCA,
      :percentil=>95, 
      :debug=>false
    }
    
    @opts=opts_default.merge(opts)
    opts_default.keys.each {|k| send("#{k}=", @opts[k]) }
  end
  def summary
    ReportBuilder.new(:no_title=>true).add(self).to_text
  end
  def number_of_factors
    total=0
    ds_eigenvalues.fields.each_with_index do |f,i|
      total+=1 if (@original[i]>ds_eigenvalues[f].percentil(percentil))
    end
    total
  end
  def report_building(g)
    g.section(:name=>@name) do |s|
      s.text "Method: #{bootstrap_method}"
      s.text "Number of variables: #{@n_variables}"
      s.text "Number of cases: #{@n_cases}"
      s.text "Number of iterations: #{@iterations}"
      s.text "Number or factors to preserve: #{number_of_factors}"
      s.table(:name=>"Eigenvalues", :header=>["Eigenvalue", "actual", "mean","p.#{percentil}","preserve?"]) do |t|
        ds_eigenvalues.fields.each_with_index do |f,i|
          v=ds_eigenvalues[f]
          t.row [i+1, "%0.4f" % @original[i], "%0.4f" %  v.mean, "%0.4f" %  v.percentil(percentil), (@original[i] > v.percentil(percentil)) ? "Yes":""]
        end
      end
      
    end
  end
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
          ds_bootstrap[f]=@n_cases.times.map {|c| rng.gaussian( @ds[f].sd)+@ds[f].mean}.to_scale
        elsif bootstrap_method==:raw_data
          ds_bootstrap[f]=ds[f].sample_with_replacement(@n_cases).to_scale
        end
      end
      fa=factor_class.new(Statsample::Bivariate.correlation_matrix(ds_bootstrap), :m=>@n_variables)
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
