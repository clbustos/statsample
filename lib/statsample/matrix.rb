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

class ::Matrix
  def to_gsl
    out=[]
    self.row_size.times{|i|
      out[i]=self.row(i).to_a
    }
    GSL::Matrix[*out]
  end

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
  attr :labels
  attr :name
  module CorrelationMatrix
    def summary
      rp=ReportBuilder.new()
      rp.add(self)
      rp.to_text
    end
    def labels=(v)
      @labels=v
    end
    def name=(v)
      @name=v
    end
    def to_reportbuilder(generator)
      @name||="Correlation Matrix"
      @labels||=row_size.times.collect {|i| i.to_s} 
      t=ReportBuilder::Table.new(:name=>@name, :header=>[""]+@labels)
      row_size.times {|i|
        t.add_row([@labels[i]]+@rows[i].collect {|i| sprintf("%0.3f",i).gsub("0.",".")})
      }
      generator.parse_element(t)
    end
  end
end
