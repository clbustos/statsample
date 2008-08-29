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
			base.update(RubySS::vector_cols_matrix(@v_rows,@v_cols).to_a.to_vector.frequencies)
		end
        def to_matrix
            f=frequencies
            rn=rows_names
            cn=cols_names
            Matrix.rows(rn.collect{|row|
                cn.collect{|col| f[[row,col]]}
            })
        end
        def frequencies_by_row
            f=frequencies
            rows_names.inject({}){|sr,row|
                sr[row]=cols_names.inject({}) {|sc,col|
                    sc[col]=f[[row,col]]
                    sc
                }
                sr
            }
        end
        def frequencies_by_col
            f=frequencies
            cols_names.inject({}){|sc,col|
                sc[col]=rows_names.inject({}) {|sr,row|
                    sr[row]=f[[row,col]]
                    sr
                }
                sc
            }
        end
        # Useful to obtain chi square
        def matrix_expected
            rn=rows_names
            cn=cols_names
            rt=rows_total
            ct=cols_total
            t=@v_rows.size.to_f
            m=rn.collect{|row|
                cn.collect{|col|
                    (rt[row]*ct[col]) / t 
                }
            }
            Matrix.rows(m)
        end
        def to_s
            fq=frequencies
            rn=rows_names
            cn=cols_names
            max_row_size = rn.inject(0) {|s,x| x.to_s.size>s ? x.to_s.size : s}
            max_col_size = cn.inject(0) {|s,x| x.to_s.size>s ? x.to_s.size : s}
            max_col_size = frequencies.inject(max_col_size) {|s,x| x[1].to_s.size>s ? x[1].to_s.size : s}
            
            out=""
            out << " " * (max_row_size+2) << "|" << cn.collect{|c| c=c.to_s; " "+c+(" "*(max_col_size-c.size))+" "}.join("|") << "|\n"
            out << "-" * (max_row_size+2) << "|" << ("-"*(max_col_size+2) +"|")*cn.size << "\n"
            rn.each{|row|
                out << " " +row.to_s  << " "*(max_row_size-row.to_s.size) << " | "
                cn.each{|col|
                    data=fq[[row,col]].to_s
                    out << " " << data << " "*(max_col_size-data.size) << "| "
                }
            out << "\n"
            }
            out
        end
	end
end
