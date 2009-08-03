module Statsample
module Regression
module Multiple
# Pure Ruby Class for Multiple Regression Analysis.
# Slower than AlglibEngine, but is pure ruby and uses a pairwise aproach for missing values. 
# If you need listwise aproach for missing values, use AlglibEngine, because is faster.
# 
# Example:
#
#   @a=[1,3,2,4,3,5,4,6,5,7].to_vector(:scale)
#   @b=[3,3,4,4,5,5,6,6,4,4].to_vector(:scale)
#   @c=[11,22,30,40,50,65,78,79,99,100].to_vector(:scale)
#   @y=[3,4,5,6,7,8,9,10,20,30].to_vector(:scale)
#   ds={'a'=>@a,'b'=>@b,'c'=>@c,'y'=>@y}.to_dataset
#   lr=Statsample::Regression::Multiple::RubyEngine.new(ds,'y')

class RubyEngine < BaseEngine 
    def initialize(ds,y_var)
    super
        @dy=ds[@y_var]
        @ds_valid=ds.dup_only_valid
        @ds_indep=ds.dup(ds.fields-[y_var])
        @fields=@ds_indep.fields
        set_dep_columns
        obtain_y_vector
        @matrix_x = Bivariate.correlation_matrix(@ds_indep)
        @coeffs_stan=(@matrix_x.inverse * @matrix_y).column(0).to_a
@min_n_valid=nil
    end
    def min_n_valid
        if @min_n_valid.nil?
            min=@ds.cases
            m=Bivariate::n_valid_matrix(@ds)
            for x in 0...m.row_size
                for y in 0...m.column_size
                    min=m[x,y] if m[x,y] < min
                end
            end
            @min_n_valid=min
        end
        @min_n_valid
    end
    def set_dep_columns
        @dep_columns=[]
        @ds_indep.each_vector{|k,v|
            @dep_columns.push(v.data_with_nils)
        }                
    end
    # Sum of square total
    def sst
        #if @sst.nil?
        @sst=@dy.variance*(min_n_valid-1.0)
        #end
        @sst
    end
    def r2
        if @r2.nil?
        c=@matrix_y
        rxx=obtain_predictor_matrix
        matrix=(c.t*rxx.inverse*c)
        @r2=matrix[0,0]
        end
        @r2
    end
    def r
        Math::sqrt(r2)
    end

    def df_e
        min_n_valid-@dep_columns.size-1
    end
    def fix_with_mean
        i=0
        @ds_indep.each{|row|
            empty=[]
            row.each{|k,v|
                empty.push(k) if v.nil?
            }
            if empty.size==1
                @ds_indep[empty[0]][i]=@ds[empty[0]].mean
            end
            i+=1
        }
        @ds_indep.update_valid_data
        set_dep_columns
    end
    def fix_with_regression
        i=0
        @ds_indep.each{|row|
            empty=[]
            row.each{|k,v|
                empty.push(k) if v.nil?
            }
            if empty.size==1
                field=empty[0]
                lr=MultipleRegression.new(@ds_indep,field)
                fields=[]
                @ds_indep.fields.each{|f|
                    fields.push(row[f]) unless f==field
                }
                @ds_indep[field][i]=lr.process(fields)
            end
            i+=1
        }
        @ds_indep.update_valid_data
        set_dep_columns
    end
    def obtain_y_vector
        @matrix_y=Matrix.columns([@ds_indep.fields.collect{|f|
                Bivariate.pearson(@dy, @ds_indep[f])
        }])
    end
    def obtain_predictor_matrix
        Bivariate::correlation_matrix(@ds_indep)
    end
    def constant
        c=coeffs
        @dy.mean-@fields.inject(0){|a,k| a+(c[k] * @ds_indep[k].mean)}
    end
   
    def coeffs
        sc=standarized_coeffs
        assign_names(@fields.collect{|f|
            (sc[f]*@dy.sds).quo(@ds_indep[f].sds)
        })
    end
    def standarized_coeffs
        assign_names(@coeffs_stan)
    end
end
end
end
end
