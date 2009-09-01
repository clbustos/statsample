require 'matrix'
class Matrix
    def rows_sum
        (0...row_size).collect {|i|
            row(i).to_a.inject(0) {|a,v| a+v}
        }
    end
    def cols_sum
        (0...column_size).collect {|i|
            column(i).to_a.inject(0) {|a,v| a+v}
        }
    end
    def total_sum
        rows_sum.inject(0){|a,v| a+v}
    end
    def row_stochastic
        rs=rows_sum
        rows=(0...row_size).collect{|i|
            (0...column_size).collect {|j|
                self[i,j].quo(rs[i])
            }
        }
        Matrix.rows(rows,false)
    end
    def column_stochastic
        cs=cols_sum
        rows=(0...row_size).collect{|i|
            (0...column_size).collect {|j|
                self[i,j].quo(cs[j])
            }
        }
        Matrix.rows(rows,false)
    end
    def double_stochastic
        ts=total_sum
        collect {|i| i.quo(ts)}
    end
    # Test if a Matrix is a identity one
    def identity?
        if regular?
            rows=(0...row_size).each{|i|
                (0...column_size).each {|j|
                    v = self[i,j]
                    return false if (i==j and v!=1) or (i!=j and v!=0)
                }
            }
            true
        else
            false
        end
    end
    def to_gsl
        out=[]
        self.row_size.times{|i|
            out[i]=self.row(i).to_a
        }
        GSL::Matrix[*out]
    end
    def orthogonal?
        if regular?
            (self * self.t).identity?
        else
            false
        end
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
