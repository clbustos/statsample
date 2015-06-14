class ::Vector
  def to_matrix
    ::Matrix.columns([self.to_a])
  end
  def to_vector
    self
  end
end
class ::Matrix
  def to_matrix
    self
  end

  def to_dataframe
    f = (self.respond_to? :fields_y) ? fields_y : column_size.times.map {|i| "VAR_#{i+1}".to_sym }
    f = [f] unless f.is_a?(Array)
    ds = Daru::DataFrame.new({}, order: f)
    f.each do |ff|
      ds[ff].rename ff
    end
    row_size.times {|i|
      ds.add_row(self.row(i).to_a)
    }
    ds.update
    ds.rename(self.name) if self.respond_to? :name
    ds
  end

  alias :to_dataset :to_dataframe

  if defined? :eigenpairs
    alias_method :eigenpairs_ruby, :eigenpairs
  end

  if Statsample.has_gsl?
    # Optimize eigenpairs of extendmatrix module using gsl
    def eigenpairs
      to_gsl.eigenpairs
    end
  end

  def eigenvalues
    eigenpairs.collect {|v| v[0]}
  end

  def eigenvectors
    eigenpairs.collect {|v| v[1]}
  end

  def eigenvectors_matrix
    Matrix.columns(eigenvectors)
  end

  def to_gsl
    out=[]
    self.row_size.times{|i|
      out[i]=self.row(i).to_a
    }
    GSL::Matrix[*out]
  end

  def []=(i, j, x)
    @rows[i][j] = x
  end
end

module GSL
  class Vector
    class Col
      def to_matrix
      ::Matrix.columns([self.size.times.map {|i| self[i]}])
      end

      def to_ary
        to_a
      end

      def to_gsl
        self
      end
    end
  end
  class Matrix
    def to_gsl
      self
    end

    def to_dataframe
      f = (self.respond_to? :fields_y) ? fields_y : column_size.times.map { |i| "VAR_#{i+1}".to_sym }
      ds=Daru::DataFrame.new({}, order: f)
      f.each do |ff|
        ds[ff].rename ff
      end

      row_size.times {|i|
        ds.add_row(self.row(i).to_a)
      }
      ds.update
      ds.rename(self.name) if self.respond_to? :name
      ds
    end

    alias :to_dataset :to_dataframe

    def row_size
      size1
    end

    def column_size
      size2
    end

    def determinant
      det
    end

    def inverse
      GSL::Linalg::LU.invert(self)
    end

    def eigenvalues
      eigenpairs.collect {|v| v[0]}
    end

    def eigenvectors
      eigenpairs.collect {|v| v[1]}
    end

    # Matrix sum of squares
    def mssq
      sum=0
      to_v.each {|i| sum+=i**2}
      sum
    end

    def eigenvectors_matrix
      eigval, eigvec= GSL::Eigen.symmv(self)
      GSL::Eigen::symmv_sort(eigval, eigvec, GSL::Eigen::SORT_VAL_DESC)
      eigvec
    end

    def eigenpairs
      eigval, eigvec= GSL::Eigen.symmv(self)
      GSL::Eigen::symmv_sort(eigval, eigvec, GSL::Eigen::SORT_VAL_DESC)
      @eigenpairs=eigval.size.times.map {|i|
        [eigval[i],eigvec.get_col(i)]
      }
    end

    #def eigenpairs_ruby
    #  self.to_matrix.eigenpairs_ruby
    #end
    def square?
      size1==size2
    end

    def to_matrix
      rows=self.size1
      cols=self.size2
      out=(0...rows).collect{|i| (0...cols).collect {|j| self[i,j]} }
      ::Matrix.rows(out)
    end
    
    def total_sum
      sum=0
      size1.times {|i|
        size2.times {|j|
          sum+=self[i,j]
        }
      }
      sum
    end
  end
end

module Statsample
  # Module to add names to X and Y fields
  module NamedMatrix
    include Summarizable

    def fields
    raise "Should be square" if !square?
    fields_x
    end
    def fields=(v)
    raise "Matrix should be square" if !square?
    @fields_x=v
    @fields_y=v
    end
    def fields_x=(v)
    raise "Size of fields != row_size" if v.size!=row_size
    @fields_x=v
    end
    def fields_y=(v)
    raise "Size of fields != column_size" if v.size!=column_size
    @fields_y=v
    end
    def fields_x
    @fields_x||=row_size.times.collect {|i| _("X%d") % i}
    end
    def fields_y
    @fields_y||=column_size.times.collect {|i| _("Y%d") % i}
    end

    def name
      @name||=get_new_name
    end
    def name=(v)
      @name=v
    end
    def get_new_name
      @@named_matrix||=0
      @@named_matrix+=1
      _("Matrix %d") % @@named_matrix
    end

  end
  # Module to add method for variance/covariance and correlation matrices
  # == Usage
  #  matrix=Matrix[[1,2],[2,3]]
  #  matrix.extend CovariateMatrix
  #
  module CovariateMatrix
    include NamedMatrix
    @@covariatematrix=0

    # Get type of covariate matrix. Could be :covariance or :correlation
    def _type
      if row_size==column_size
        if row_size.times.find {|i| self[i,i]!=1.0}
          :covariance
        else
          :correlation
        end
      else
        @type
      end

    end
    def _type=(t)
      @type=t
    end
    def correlation
      if(_type==:covariance)
        matrix=Matrix.rows(row_size.times.collect { |i|
          column_size.times.collect { |j|
            if i==j
              1.0
            else
              self[i,j].quo(Math::sqrt(self[i,i])*Math::sqrt(self[j,j]))
            end
          }
        })
        matrix.extend CovariateMatrix
        matrix.fields_x=fields_x
        matrix.fields_y=fields_y
        matrix._type=:correlation
        matrix
      else
        self
      end
    end


    # Get variance for field k
    #
    def variance(k)
      submatrix([k])[0,0]
    end

    def get_new_name
      @@covariatematrix+=1
      _("Covariate matrix %d") % @@covariatematrix
    end

    # Select a submatrix of factors. If you have a correlation matrix
    # with a, b and c, you could obtain a submatrix of correlations of
    # a and b, b and c or a and b
    #
    # You could use labels or index to select the factors.
    # If you don't specify columns, its will be equal to rows.
    #
    # Example:
    #   a=Matrix[[1.0, 0.3, 0.2],
    #            [0.3, 1.0, 0.5],
    #            [0.2, 0.5, 1.0]]
    #   a.extend CovariateMatrix
    #   a.fields=%w{a b c}
    #   a.submatrix(%w{c a}, %w{b})
    #   => Matrix[[0.5],[0.3]]
    #   a.submatrix(%w{c a})
    #   => Matrix[[1.0, 0.2] , [0.2, 1.0]]
    def submatrix(rows,columns = nil)
      raise ArgumentError, "rows shouldn't be empty" if rows.respond_to? :size and rows.size == 0
      columns ||= rows
      # Convert all fields on index
      row_index = rows.collect do |v|
        r = v.is_a?(Numeric) ? v : fields_x.index(v)
        raise "Index #{v} doesn't exists on matrix" if r.nil?
        r
      end

      column_index = columns.collect do |v|
        r = v.is_a?(Numeric) ? v : fields_y.index(v)
        raise "Index #{v} doesn't exists on matrix" if r.nil?
        r
      end


      fx=row_index.collect {|v| fields_x[v]}
      fy=column_index.collect {|v| fields_y[v]}

      matrix = Matrix.rows(row_index.collect { |i| column_index.collect { |j| self[i, j] }})
      matrix.extend CovariateMatrix
      matrix.fields_x = fx
      matrix.fields_y = fy
      matrix._type = _type
      matrix
    end
    def report_building(generator)
      @name||= (_type==:correlation ? _("Correlation"):_("Covariance"))+_(" Matrix")
      generator.table(:name=>@name, :header=>[""]+fields_y) do |t|
        row_size.times {|i|
          t.row([fields_x[i]]+row(i).to_a.collect {|i1|
              i1.nil? ? "--" : sprintf("%0.3f",i1).gsub("0.",".")
          })
        }
      end
    end
  end
end
