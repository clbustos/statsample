require 'rubyss/vector'
module RubySS
	# Class to create crosstab of data
	# With this, you can create reports and do chi square test
	# The first vector will be at rows and the second will the the columns
	#
    class Crosstab
		attr_reader :v_rows, :v_cols
		def initialize(v1,v2)
			raise ArgumentError, "Both arguments should be Vectors" unless v1.instance_of? Vector and v2.instance_of? Vector
			raise ArgumentError, "Vectors should be the same size" unless v1.size==v2.size
			@v_rows,@v_cols=v1,v2
		end	
		def rows_names
			@v_rows.factors.sort
		end
		def cols_names
			@v_cols.factors.sort
		end
		def rows_total
			@v_rows.frequencies
		end
		def cols_total
			@v_cols.frequencies
		end
		def frequencies
			base=rows_names.inject([]){|s,row| 
				s+=cols_names.collect{|col| [row,col]}
			}.inject({}) {|s,par|
				s[par]=0
				s
			}
			base.update(RubySS::vector_matrix(@v_rows,@v_cols).to_vector.frequencies)
		end
	end
end
