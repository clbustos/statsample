module Statsample
module Factor
  # Principal Component Analysis (PCA) of a 
  # covariance or correlation matrix. 
  #
  # For Principal Axis Analysis, use Statsample::Factor::PrincipalAxis
  # 
  # == Usage:
  #   require 'statsample'
  #   a=[2.5, 0.5, 2.2, 1.9, 3.1, 2.3, 2.0, 1.0, 1.5, 1.1].to_scale
  #   b=[2.4,0.7,2.9,2.2,3.0,2.7,1.6,1.1,1.6,0.9].to_scale
  #   ds={'a'=>a,'b'=>b}.to_dataset
  #   cor_matrix=Statsample::Bivariate.correlation_matrix(ds)
  #   pca=Statsample::Factor::PCA.new(cor_matrix)
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
  #
  # * SPSS manual
  # * Smith, L. (2002). A tutorial on Principal Component Analysis. Available on http://courses.eas.ualberta.ca/eas570/pca_tutorial.pdf 
  # 
  class PCA
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
    include Summarizable
    
    def initialize(matrix, opts=Hash.new)
      @use_gsl=nil
      @name=_("Principal Component Analysis")
      @matrix=matrix
      @n_variables=@matrix.column_size
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
        @variables_names=@n_variables.times.map {|i| "V#{i+1}"}
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
    def create_centered_ds
      h={}
      @original_ds.factors.each {|f|
        mean=@original_ds[f].mean
        h[f]=@original_ds[f].recode {|c| c-mean}
      }
      @ds=h.to_dataset
    end
    
    # Feature vector for m factors
    def feature_vector(m=nil)
      m||=@m
      omega_m=::Matrix.build(@n_variables, m) {0}
      m.times do |i|
        omega_m.column= i, @eigenpairs[i][1]
      end
      omega_m
    end
    # data_transformation
    def data_transformation(data_matrix, m)
      m||=@m
      raise "Data variables number should be equal to original variable number" if data_matrix.size2!=@n_variables
      fv=feature_vector(m)
      (fv.transpose*data_matrix.transpose).transpose
    end
    # Component matrix for m factors
    def component_matrix(m=nil)
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
      cm.fields_y = m.times.map {|i| "component_#{i+1}"}
      cm
    end
    # Communalities for all variables given m factors
    def communalities(m=nil)
      m||=@m
      h=[]
      @n_variables.times do |i|
        sum=0
        m.times do |j|
          sum+=@eigenpairs[j][0].abs*@eigenpairs[j][1][i]**2
        end
        h.push(sum)
      end
      h
    end
    # Array with eigenvalues
    def eigenvalues
      @eigenpairs.collect {|c| c[0] }
    end
    
    def calculate_eigenpairs
      if @use_gsl
        calculate_eigenpairs_gsl
      else
        calculate_eigenpairs_ruby
      end
    end
  
    def calculate_eigenpairs_ruby
      eigval, eigvec= @matrix.eigenvaluesJacobi, @matrix.cJacobiV
      @eigenpairs={}
      eigval.to_a.each_index {|i|
        @eigenpairs[eigval[i]]=eigvec.column(i)
      }
      @eigenpairs=@eigenpairs.sort.reverse
    end
    def calculate_eigenpairs_gsl
      eigval, eigvec= GSL::Eigen.symmv(@matrix.to_gsl)
        @eigenpairs={}
        eigval.each_index {|i|
          @eigenpairs[eigval[i]]=eigvec.get_col(i)
        }
        @eigenpairs=@eigenpairs.sort.reverse
    end
    
    def report_building(builder) # :nodoc:
      builder.section(:name=>@name) do |generator|
      generator.text _("Number of factors: %d") % m
      generator.table(:name=>_("Communalities"), :header=>[_("Variable"),_("Initial"),_("Extraction")]) do |t|
        communalities(m).each_with_index {|com, i|
          t.row([@variables_names[i], 1.0, sprintf("%0.3f", com)])
        }
      end
      
      generator.table(:name=>_("Eigenvalues"), :header=>[_("Variable"),_("Value")]) do |t|
        eigenvalues.each_with_index {|eigenvalue, i|
          t.row([@variables_names[i], sprintf("%0.3f",eigenvalue)])
        }
      end
=begin      
      generator.table(:name=>_("Component Matrix"), :header=>[_("Variable")]+m.times.collect {|c| c+1}) do |t|
        i=0
        component_matrix(m).to_a.each do |row|
          t.row([@variables_names[i]]+row.collect {|c| sprintf("%0.3f",c)})
          i+=1
        end
      end
=end
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
