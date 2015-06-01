# encoding: UTF-8
module Statsample
module Factor
  # Principal Component Analysis (PCA) of a covariance or 
  # correlation matrix.. 
  #
  # NOTE: Sign of second and later eigenvalues could be different
  # using Ruby or GSL, so values for PCs and component matrix
  # should differ, because extendmatrix and gsl's methods to calculate
  # eigenvectors are different. Using R is worse, cause first 
  # eigenvector could have negative values!
  # For Principal Axis Analysis, use Statsample::Factor::PrincipalAxis
  # 
  # == Usage:
  #   require 'statsample'
  #   a = Daru::Vector.new([2.5, 0.5, 2.2, 1.9, 3.1, 2.3, 2.0, 1.0, 1.5, 1.1])
  #   b = Daru::Vector.new([2.4,0.7,2.9,2.2,3.0,2.7,1.6,1.1,1.6,0.9])
  #   ds = Daru::DataFrame.new({:a => a,:b => b})
  #   cor_matrix = Statsample::Bivariate.correlation_matrix(ds)
  #   pca=  Statsample::Factor::PCA.new(cor_matrix)
  #   pca.m
  #   => 1
  #   pca.eigenvalues
  #   => [1.92592927269225, 0.0740707273077545]
  #   pca.component_matrix
  #   => GSL::Matrix
  #   [  9.813e-01 
  #     9.813e-01 ]
  #   pca.communalities
  #   => [0.962964636346122, 0.962964636346122]
  #
  # == References:
  # * SPSS Manual
  # * Smith, L. (2002). A tutorial on Principal Component Analysis. Available on http://courses.eas.ualberta.ca/eas570/pca_tutorial.pdf 
  # * Härdle, W. & Simar, L. (2003). Applied Multivariate Statistical Analysis. Springer
  # 
  class PCA
    include Summarizable
    # Name of analysis
    attr_accessor :name

    # Number of factors. Set by default to the number of factors
    # with eigen values > 1
    attr_accessor :m
    # Use GSL if available
    attr_accessor :use_gsl
    # Add to the summary a rotation report
    attr_accessor :summary_rotation
    # Add to the summary a parallel analysis report
    attr_accessor :summary_parallel_analysis
    # Type of rotation. By default, Statsample::Factor::Rotation::Varimax
    attr_accessor :rotation_type
    attr_accessor :matrix_type
    def initialize(matrix, opts=Hash.new)
      @use_gsl = opts[:use_gsl]
      opts.delete :use_gsl

      @name=_("Principal Component Analysis")
      @matrix=matrix
      @n_variables=@matrix.column_size      
      @variables_names=(@matrix.respond_to? :fields) ? @matrix.fields : @n_variables.times.map {|i| "VAR_#{i+1}".to_sym }
      
      @matrix_type = @matrix.respond_to?(:_type) ? @matrix._type : :correlation
      
      @m=nil
      
      @rotation_type=Statsample::Factor::Varimax
      
      opts.each{|k,v|
        self.send("#{k}=",v) if self.respond_to? k
      }

      if @use_gsl.nil?
        @use_gsl=Statsample.has_gsl?
      end
      if @matrix.respond_to? :fields
        @variables_names=@matrix.fields
      else
        @variables_names=@n_variables.times.map {|i| "V#{i+1}".to_sym}
      end
      calculate_eigenpairs
      
      if @m.nil?
        # Set number of factors with eigenvalues > 1
        @m=@eigenpairs.find_all {|ev,ec| ev>=1.0}.size
      end
    end
    def rotation
      @rotation_type.new(component_matrix)
    end
    def total_eigenvalues
      eigenvalues.inject(0) {|ac,v| ac+v}
    end
    def create_centered_ds
      h={}
      @original_ds.factors.each {|f|
        mean = @original_ds[f].mean
        h[f] = @original_ds[f].recode {|c| c-mean}
      }
      @ds = Daru::DataFrame.new(h)
    end
    
    # Feature matrix for +m+ factors
    # Returns +m+ eigenvectors as columns.
    # So, i=variable, j=component
    def feature_matrix(m=nil)
      m||=@m
      if @use_gsl
        omega_m=GSL::Matrix.zeros(@n_variables,m)
        ev=eigenvectors
        m.times do |i|
          omega_m.set_column(i,ev[i])
        end
        omega_m
      else
        omega_m=::Matrix.build(@n_variables, m) {0}
        m.times do |i|
          omega_m.column= i, @eigenpairs[i][1]
        end
        omega_m
      end
    end
    # Returns Principal Components for +input+ matrix or dataset
    # The number of PC to return is equal to parameter +m+. 
    # If +m+ isn't set, m set to number of PCs selected at object creation.
    # Use covariance matrix
    
    def principal_components(input, m=nil)
      if @use_gsl
        data_matrix=input.to_gsl
      else
        data_matrix=input.to_matrix
      end
      m||=@m
      
      raise "data matrix variables<>pca variables" if data_matrix.column_size!=@n_variables
      
      fv=feature_matrix(m)
      pcs=(fv.transpose*data_matrix.transpose).transpose
      
      pcs.extend Statsample::NamedMatrix
      pcs.fields_y = m.times.map { |i| "PC_#{i+1}".to_sym }
      pcs.to_dataframe
    end
    def component_matrix(m=nil)
      var="component_matrix_#{matrix_type}"
      send(var,m)
    end
    # Matrix with correlations between components and
    # variables. Based on Härdle & Simar (2003, p.243)
    def component_matrix_covariance(m=nil)
      m||=@m
      raise "m should be > 0" if m<1
      ff=feature_matrix(m)
      cm=::Matrix.build(@n_variables, m) {0}
      @n_variables.times {|i|
        m.times {|j|
          cm[i,j]=ff[i,j] * Math.sqrt(eigenvalues[j] / @matrix[i,i])
        }
      }
      cm.extend NamedMatrix
      cm.name=_("Component matrix (from covariance)")
      cm.fields_x = @variables_names
      cm.fields_y = m.times.map {|i| "PC_#{i+1}".to_sym }
      
      cm
    end
    # Matrix with correlations between components and
    # variables
    def component_matrix_correlation(m=nil)
      m||=@m
      raise "m should be > 0" if m<1
      omega_m=::Matrix.build(@n_variables, m) {0}
      gammas=[]
      m.times {|i|
        omega_m.column=i, @eigenpairs[i][1]
        gammas.push(Math::sqrt(@eigenpairs[i][0]))
      }
      gamma_m=::Matrix.diagonal(*gammas)
      cm=(omega_m*(gamma_m)).to_matrix
      
      cm.extend CovariateMatrix
      cm.name=_("Component matrix")
      cm.fields_x = @variables_names
      cm.fields_y = m.times.map { |i| "PC_#{i+1}".to_sym }
      cm
    end
    def communalities(m=nil)
      m||=@m
      h=[]
      @n_variables.times do |i|
        sum=0
        m.times do |j|
          sum += (@eigenpairs[j][0].abs*@eigenpairs[j][1][i]**2)
        end
        h.push(sum)
      end
      h
    end
    # Array with eigenvalues
    def eigenvalues
      @eigenpairs.collect {|c| c[0] }
    end
    def eigenvectors
      @eigenpairs.collect {|c| 
        @use_gsl ? c[1].to_gsl : Daru::Vector.new(c[1])
      }
    end
    def calculate_eigenpairs
      @eigenpairs= @use_gsl ? @matrix.to_gsl.eigenpairs : @matrix.to_matrix.eigenpairs_ruby
    end
  
    
    def report_building(builder) # :nodoc:
      builder.section(:name=>@name) do |generator|
        generator.text _("Number of factors: %d") % m
        generator.table(:name=>_("Communalities"), :header=>[_("Variable"),_("Initial"),_("Extraction"), _("%")]) do |t|
          communalities(m).each_with_index {|com, i|
            perc=com*100.quo(@matrix[i,i])
            t.row([@variables_names[i], "%0.3f" % @matrix[i,i]  , "%0.3f" % com, "%0.3f" % perc])
          }
        end
        te=total_eigenvalues
        generator.table(:name=>_("Total Variance Explained"), :header=>[_("Component"), _("E.Total"), _("%"), _("Cum. %")]) do |t|
          ac_eigen=0
          eigenvalues.each_with_index {|eigenvalue,i|
            ac_eigen+=eigenvalue
            t.row([_("Component %d") % (i+1), sprintf("%0.3f",eigenvalue), sprintf("%0.3f%%", eigenvalue*100.quo(te)), sprintf("%0.3f",ac_eigen*100.quo(te))])
          }
        end
        
        generator.parse_element(component_matrix(m))
                  
        if (summary_rotation)
          generator.parse_element(rotation)
        end
      end
    end
    private :calculate_eigenpairs, :create_centered_ds
  end
end
end
