require 'extendmatrix'


class ::Matrix
  def to_matrix
    self
  end
  
  def to_gsl
    out=[]
    self.row_size.times{|i|
      out[i]=self.row(i).to_a
    }
    GSL::Matrix[*out]
  end
end

module GSL
  class Matrix
    def to_gsl
      self
    end
    def to_matrix
      rows=self.size1
      cols=self.size2
      out=(0...rows).collect{|i| (0...cols).collect {|j| self[i,j]} }
      ::Matrix.rows(out)
    end
  end
end

module Statsample
  # Module to add method for variance/covariance and correlation matrices
  # == Usage
  #  matrix=Matrix[[1,2],[2,3]]
  #  matrix.extend CovariateMatrix
  # 
  module CovariateMatrix
    include Summarizable
    @@covariatematrix=0

    # Get type of covariate matrix. Could be :covariance or :correlation
    def type
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
    def type=(t)
      @type=t
    end
    def correlation
      if(type==:covariance)
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
        matrix.type=:correlation
        matrix
      else
        self
      end
    end
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
    
    def name=(v)
      @name=v
    end
    def name
      @name||=get_new_name
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
    #   a.extends CovariateMatrix
    #   a.labels=%w{a b c}
    #   a.submatrix(%{c a}, %w{b})
    #   => Matrix[[0.5],[0.3]]
    #   a.submatrix(%{c a})
    #   => Matrix[[1.0, 0.2] , [0.2, 1.0]]
    def submatrix(rows,columns=nil)
      raise ArgumentError, "rows shouldn't be empty" if rows.respond_to? :size and rows.size==0
      columns||=rows
      # Convert all labels on index
      row_index=rows.collect {|v| 
        v.is_a?(Numeric) ? v : fields_x.index(v)
      }
      column_index=columns.collect {|v| 
        v.is_a?(Numeric) ? v : fields_y.index(v)
      }

      fx=row_index.collect {|v| fields_x[v]}
      fy=column_index.collect {|v| fields_y[v]}
        
      matrix= Matrix.rows(row_index.collect {|i|
        row=column_index.collect {|j| self[i,j]}})
      matrix.extend CovariateMatrix 
      matrix.fields_x=fx
      matrix.fields_y=fy
      matrix.type=type
      matrix
    end
    def report_building(generator)
      @name||= (type==:correlation ? _("Correlation"):_("Covariance"))+_(" Matrix")
      generator.table(:name=>@name, :header=>[""]+fields_y) do |t|
        row_size.times {|i|
          t.row([fields_x[i]]+@rows[i].collect {|i1| sprintf("%0.3f",i1).gsub("0.",".")})
        }
      end
    end
  end
end
