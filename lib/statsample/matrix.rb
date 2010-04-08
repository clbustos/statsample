require 'matrix'

class ::Vector
  if RUBY_VERSION<="1.9.0"
    alias_method :old_coerce, :coerce
    def coerce(other)
      case other
      when Numeric
        return Matrix::Scalar.new(other), self
      else
        raise TypeError, "#{self.class} can't be coerced into #{other.class}"
      end
    end
    
  end
end


class ::Matrix
  def to_gsl
    out=[]
    self.row_size.times{|i|
      out[i]=self.row(i).to_a
    }
    GSL::Matrix[*out]
  end
  # Calculate marginal of rows
  def row_sum
  (0...row_size).collect {|i|
    row(i).to_a.inject(0) {|a,v| a+v}
  }
  end
  # Calculate marginal of columns
  def column_sum
  (0...column_size).collect {|i|
    column(i).to_a.inject(0) {|a,v| a+v}
  }
  end

  
  alias :old_par :[]
  
  # Select elements and submatrixes
  # Implement row, column and minor in one method
  # 
  # * [i,j]:: Element i,j
  # * [i,:*]:: Row i
  # * [:*,j]:: Column j
  # * [i1..i2,j]:: Row i1 to i2, column j
  
  def [](*args)
    raise ArgumentError if args.size!=2
    x=args[0]
    y=args[1]
    if x.is_a? Integer and y.is_a? Integer
      @rows[args[0]][args[1]]
    else
      # set ranges according to arguments
      
      rx=case x
        when Numeric
          x..x
        when :*
          0..(row_size-1)
        when Range
          x
      end
      ry=case y
        when Numeric
          y..y
        when :*
          0..(column_size-1)
        when Range
          y
      end
      Matrix.rows(rx.collect {|i| ry.collect {|j| @rows[i][j]}})
    end
  end
  # Calculate sum of cells
  def total_sum
    row_sum.inject(0){|a,v| a+v}
  end

end

module GSL
  class Matrix
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
    # Gives a nice 
    def summary
      rp=ReportBuilder.new()
      rp.add(self)
      rp.to_text
    end
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
      @fields_x
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
      if @fields_x.nil?
        @fields_x=row_size.times.collect {|i| i} 
      end
      @fields_x
    end
    def fields_y
      if @fields_y.nil?
        @fields_y=column_size.times.collect {|i| i} 
      end
      @fields_y
    end
    
    def name=(v)
      @name=v
    end
    def name
      @name
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
      @name||= (type==:correlation ? "Correlation":"Covariance")+" Matrix"
      generator.table(:name=>@name, :header=>[""]+fields_y) do |t|
        row_size.times {|i|
          t.row([fields_x[i]]+@rows[i].collect {|i1| sprintf("%0.3f",i1).gsub("0.",".")})
        }
      end
    end
  end
end
