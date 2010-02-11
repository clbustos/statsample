require 'matrix'
if RUBY_VERSION<="1.9.0"
  class ::Vector
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

module Statsample
  # Confort derivation of standard library Matrix
  # Provides several recurrent methods 
  class Matrix < ::Matrix
    # Calculate marginal of rows
    def rows_sum
    (0...row_size).collect {|i|
      row(i).to_a.inject(0) {|a,v| a+v}
    }
    end
    # Calculate marginal of columns
    def cols_sum
    (0...column_size).collect {|i|
      column(i).to_a.inject(0) {|a,v| a+v}
    }
    end
    # Calculate sum of cells
    def total_sum
      rows_sum.inject(0){|a,v| a+v}
    end
    def to_gsl
      out=[]
      self.row_size.times{|i|
        out[i]=self.row(i).to_a
      }
      GSL::Matrix[*out]
    end
  end
end

module GSL
  class Matrix
    def to_matrix
      rows=self.size1
      cols=self.size2
      out=(0...rows).collect{|i| (0...cols).collect {|j| self[i,j]} }
      Statsample::Matrix.rows(out)
    end
  end
end

