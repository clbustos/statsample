module Statsample
module Factor
  class PCA
    attr_accessor :name, :m
    include GetText
    bindtextdomain("statsample")
    def initialize(matrix ,opts=Hash.new)
      if matrix.is_a? ::Matrix
        require 'matrix_extension'
        matrix=matrix.to_gsl
      end
      @name=""
      @matrix=matrix
      @n_variables=@matrix.size1
      
      opts.each{|k,v|
        self.send("#{k}=",v) if self.respond_to? k
      }
      calculate_eigenpairs
      if @m.nil?
        # Set number of factors with eigenvalues > 1
        @m=@eigenpairs.find_all {|v| v[0]>=1.0}.size
      end

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
      omega_m=GSL::Matrix.zeros(@n_variables, m)
      m.times do |i|
        omega_m.set_col(i, @eigenpairs[i][1])
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
      omega_m=GSL::Matrix.zeros(@n_variables, m)
      gammas=[]
      m.times {|i|
        omega_m.set_col(i, @eigenpairs[i][1])
        gammas.push(Math::sqrt(@eigenpairs[i][0]))
      }
      gamma_m=GSL::Matrix.diagonal(gammas)
      omega_m*(gamma_m)
    end
    # Communality for all variables given m factors
    def communality(m=nil)
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
    def eigenvalues
      @eigenpairs.collect {|c| c[0] }
    end
    def calculate_eigenpairs
      eigval, eigvec= GSL::Eigen.symmv(@matrix)
      @eigenpairs={}
      eigval.each_index {|i|
        @eigenpairs[eigval[i]]=eigvec.get_col(i)
      }
      @eigenpairs=@eigenpairs.sort.reverse
    end
    def to_reportbuilder(generator)
      anchor=generator.add_toc_entry(_("PCA: ")+name)
      generator.add_html "<div class='pca'>"+_("PCA")+" #{@name}<a name='#{anchor}'></a>"

      generator.add_text "Number of factors: #{m}"
      t=ReportBuilder::Table.new(:name=>_("Communalities"), :header=>["Variable","Initial","Extraction"])
      communality(m).each_with_index {|com,i|
        t.add_row([i, 1.0, sprintf("%0.3f", com)])
      }
      generator.parse_element(t)
      
      t=ReportBuilder::Table.new(:name=>_("Eigenvalues"), :header=>["Variable","Value"])
      eigenvalues.each_with_index {|eigenvalue,i|
        t.add_row([i, sprintf("%0.3f",eigenvalue)])
      }
      generator.parse_element(t)
      
      t=ReportBuilder::Table.new(:name=>_("Component Matrix"), :header=>["Variable"]+m.times.collect {|c| c+1})
      
      i=0
      component_matrix(m).to_a.each do |row|
        t.add_row([i]+row.collect {|c| sprintf("%0.3f",c)})
        i+=1
      end
      generator.parse_element(t)
      generator.add_html("</div>")
    end
  end
end
end
