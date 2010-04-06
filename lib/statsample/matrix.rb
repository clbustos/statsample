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
  
  # :section: extendmatrix.rb
  
  #
	# Iterate the elements of a matrix
	#
	def each
		@rows.each {|x| x.each {|e| yield(e)}}
		nil
	end
#
	# Set the values of a matrix
	# m = Matrix.new(3, 3){|i, j| i * 3 + j}
	# m: 0  1  2
	#    3  4  5
	#    6  7  8
	# m[1, 2] = 9 => Matrix[[0, 1, 2], [3, 4, 9], [6, 7, 8]]
	# m[2,1..2] = Vector[8, 8] => Matrix[[0, 1, 2], [3, 8, 8], [6, 7, 8]]
	# m[0..1, 0..1] = Matrix[[0, 0, 0],[0, 0, 0]] 
	# 		=> Matrix[[0, 0, 2], [0, 0, 8], [6, 7, 8]]
	#
	def []=(i, j, v)
		case i
		when Range
			if i.entries.size == 1
				self[i.begin, j] = (v.is_a?(Matrix) ? v.row(0) : v)
			else
				case j
				when Range
					if j.entries.size == 1
						self[i, j.begin] = (v.is_a?(Matrix) ? v.column(0) : v)
					else
						i.each{|l| self.row= l, v.row(l - i.begin), j}
					end
				else
					self.column= j, v, i	
				end
			end
		else
			case j
			when Range
				if j.entries.size == 1
					self[i, j.begin] = (v.is_a?(Vector) ? v[0] : v)
				else
					self.row= i, v, j
				end
			else
				@rows[i][j] = (v.is_a?(Vector) ? v[0] : v)

			end
		end		
	end	
  
  
  # Obtain for extendmatrix.rb, by Cosmin and Bonchis
  module Jacobi
		#
		# Returns the nurm of the off-diagonal element
		#
		def Jacobi.off(a)
			n = a.row_size
			sum = 0
			n.times{|i| n.times{|j| sum += a[i, j]**2 if j != i}}
			Math.sqrt(sum)
		end

		#
		# Returns the index pair (p, q) with 1<= p < q <= n and A[p, q] is the maximum in absolute value
		#
		def Jacobi.max(a)
			n = a.row_size
			max = 0
			p = 0
			q = 0
			n.times{|i|
				((i+1)...n).each{|j| 
					val = a[i, j].abs
					if val > max
						max = val
						p = i
						q = j
					end	}}
			return p, q
		end

		#
		# Compute the cosine-sine pair (c, s) for the element A[p, q]
		#
		def Jacobi.sym_schur2(a, p, q)
			if a[p, q] != 0
				tau = Float(a[q, q] - a[p, p])/(2 * a[p, q])
				if tau >= 0
					t = 1./(tau + Math.sqrt(1 + tau ** 2))
				else	
					t = -1./(-tau + Math.sqrt(1 + tau ** 2))
				end
				c = 1./Math.sqrt(1 + t ** 2)
				s = t * c
			else
				c = 1
				s = 0
			end
			return c, s
		end

		#
		# Returns the Jacobi rotation matrix
		#
		def Jacobi.J(p, q, c, s, n)
			j = Matrix.I(n)
			j[p,p] = c;
      j[p, q] = s
			j[q,p] = -s; j[q, q] = c
			j
		end
	end

	# 
	# Classical Jacobi 8.4.3 Golub & van Loan
	#
	def cJacobi(tol = 1.0e-10)
		a = self.clone
		n = row_size
		v = Matrix.I(n)
		eps = tol * a.normF
		while Jacobi.off(a) > eps
			p, q = Jacobi.max(a)
			c, s = Jacobi.sym_schur2(a, p, q)
			#print "\np:#{p} q:#{q} c:#{c} s:#{s}\n"
			j = Jacobi.J(p, q, c, s, n)
			a = j.t * a * j
			v = v * j
		end
		return a, v
	end

	#
	# Returns the aproximation matrix computed with Classical Jacobi algorithm.
	# The aproximate eigenvalues values are in the diagonal of the matrix A.
	#
	def cJacobiA(tol = 1.0e-10)
		cJacobi(tol)[0]
	end

	#
	# Returns a Vector with the eigenvalues aproximated values. 
	# The eigenvalues are computed with the Classic Jacobi Algorithm.
	#
	def eigenvaluesJacobi
		a = cJacobiA
		Vector[*(0...row_size).collect{|i| a[i, i]}]
	end

	#
	# Returns the orthogonal matrix obtained with the Jacobi eigenvalue algorithm. 
	# The columns of V are the eigenvector.
	#
	def cJacobiV(tol = 1.0e-10)
		cJacobi(tol)[1]
	end
  
  def norm(p = 2)
    Vector::Norm.sqnorm(self, p) ** (Float(1) / p)
	end
	
	def norm_frobenius
		norm
	end
	alias :normF :norm_frobenius
  
  # End of extendmatrix
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
