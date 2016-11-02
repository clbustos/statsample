module Statsample
module Regression
module Multiple
# Pure Ruby Class for Multiple Regression Analysis.
# Slower than AlglibEngine, but is pure ruby and can use a pairwise aproach for missing values. 
# Coeffient calculation uses correlation matrix between the vectors
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

class RubyEngine < MatrixEngine
  def initialize(ds,y_var, opts=Hash.new)
    matrix=ds.correlation_matrix
    fields_indep=ds.fields-[y_var]
    default={
      :y_mean=>ds[y_var].mean,
      :x_mean=>fields_indep.inject({}) {|ac,f|  ac[f]=ds[f].mean; ac},
      :y_sd=>ds[y_var].sd,
      :x_sd=>fields_indep.inject({}) {|ac,f|  ac[f]=ds[f].sd; ac},
      :cases=>Statsample::Bivariate.min_n_valid(ds)
    }
    opts=opts.merge(default)
    super(matrix, y_var, opts)
    @ds=ds
    @dy=ds[@y_var]
    @ds_valid=ds.reject_values
    @total_cases=@ds.cases
    @valid_cases=@ds_valid.cases
    @ds_indep = ds.dup(ds.fields-[y_var])
    set_dep_columns
  end
  
  def set_dep_columns
    @dep_columns=[]
    @ds_indep.each_vector{|k,v|
      @dep_columns.push(v.data_with_nils)
    }                
  end

  def fix_with_mean
    i=0
    @ds_indep.each do |row|
      empty=[]
      row.each do |k,v|
        empty.push(k) if v.nil?
      end
      if empty.size==1
        @ds_indep[empty[0]][i]=@ds[empty[0]].mean
      end
      i+=1
    end
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
  # Standard error for constant
  def constant_se
    estimated_variance_covariance_matrix[0,0]
  end
end
end
end
end
