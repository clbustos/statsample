module Statsample
	# Class to create crosstab of data
	# With this, you can create reports and do chi square test
	# The first vector will be at rows and the second will the the columns
	#
    class Crosstab
        include GetText
        bindtextdomain("statsample")
		attr_reader :v_rows, :v_cols
        attr_accessor :row_label, :column_label
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
			base.update(Statsample::vector_cols_matrix(@v_rows,@v_cols).to_a.to_vector.frequencies)
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
        # Chi square, based on expected and real matrix
        def chi_square
            require 'statsample/test'
            Statsample::Test.chi_square(self.to_matrix, matrix_expected)
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
        def cols_empty_hash
          cols_names.inject({}) {|a,x| a[x]=0;a}
        end
        
        def summary(report_type = ConsoleSummary)
            out=""
            out.extend report_type
            fq=frequencies
            rn=rows_names
            cn=cols_names
            total=0
            total_cols=cols_empty_hash
            out.add "Chi Square: #{chi_square}\n"
            out.add(_("Rows: %s\n") % @row_label) unless @row_label.nil?
            out.add(_("Columns: %s\n") % @column_label) unless @column_label.nil?
            
            t=Statsample::ReportTable.new([""]+cols_names+[_("Total")])
            rn.each{|row|
                total_row=0
                t_row=[@v_rows.labeling(row)]
                cn.each{|col|
                    data=fq[[row,col]]
                    total_row+=fq[[row,col]]
                    total+=fq[[row,col]]                    
                    total_cols[col]+=fq[[row,col]]                    
                    t_row.push(data)
                }
                t_row.push(total_row)
                t.add_row(t_row)
            }
            t.add_horizontal_line
            t_row=[_("Total")]
            cn.each{|v|
                t_row.push(total_cols[v])
            }
            t_row.push(total)
            t.add_row(t_row)
            out.parse_table(t)
            out
        end
        def to_s
            fq=frequencies
            rn=rows_names
            cn=cols_names
            total=0
            total_cols=cols_empty_hash
            max_row_size = rn.inject(0) {|s,x| sl=@v_rows.labeling(x).size; sl>s ? sl : s}
            
            max_row_size=max_row_size<6 ? 6 : max_row_size
            
            max_col_size = cn.inject(0) {|s,x| sl=@v_cols.labeling(x).size; sl>s ? sl : s}
            max_col_size = frequencies.inject(max_col_size) {|s,x| x[1].to_s.size>s ? x[1].to_s.size : s}
            
            out=""
            out << " " * (max_row_size+2) << "|" << cn.collect{|c| name=@v_cols.labeling(c); " "+name+(" "*(max_col_size-name.size))+" "}.join("|") << "| Total\n"
            linea="-" * (max_row_size+2) << "|" << ("-"*(max_col_size+2) +"|")*cn.size << "-"*7 << "\n"
            out << linea
            rn.each{|row|
                total_row=0;
                name=@v_rows.labeling(row)
                out << " " +name  << " "*(max_row_size-name.size) << " | "
                cn.each{|col|
                    data=fq[[row,col]].to_s
                    total_row+=fq[[row,col]]
                    total+=fq[[row,col]]                    
                    total_cols[col]+=fq[[row,col]]                    
                    out << " " << data << " "*(max_col_size-data.size) << "| "
                }
                out << " " << total_row.to_s
            out << "\n"
            }
            out << linea
            out << " Total " << " "*(max_row_size-5) << "| "
            cn.each{|v|
                data=total_cols[v].to_s
                out << " " << data << " "*(max_col_size-data.size) << "| "
            }
            out << " " << total.to_s
            out
        end
	end
end
