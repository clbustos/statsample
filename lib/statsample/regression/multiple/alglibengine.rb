if HAS_ALGIB
module Statsample
module Regression
module Multiple
# Class for Multiple Regression Analysis
# Requires Alglib gem and uses a listwise aproach.
# Faster than GslEngine on massive prediction use, because process is c-based.
# Prefer GslEngine if you need good memory use.
# If you need pairwise, use RubyEngine
# Example:
#
#   @a = Daru::Vector.new([1,3,2,4,3,5,4,6,5,7])
#   @b = Daru::Vector.new([3,3,4,4,5,5,6,6,4,4])
#   @c = Daru::Vector.new([11,22,30,40,50,65,78,79,99,100])
#   @y = Daru::Vector.new([3,4,5,6,7,8,9,10,20,30])
#   ds = Daru::DataFrame.new({:a => @a,:b => @b,:c => @c,:y => @y})
#   lr=Statsample::Regression::Multiple::AlglibEngine.new(ds, :y)
#            
class AlglibEngine < BaseEngine
  def initialize(ds,y_var, opts=Hash.new)
    super    
    @ds       = ds.dup_only_valid
    @ds_valid = @ds
    @dy       = @ds[@y_var]
    @ds_indep = ds.dup(ds.vectors.to_a - [y_var])
    # Create a custom matrix
    columns = []
    @fields = []
    @ds.vectors.each do |f|
      if f != @y_var
        columns.push(@ds[f].to_a)
        @fields.push(f)
      end
    end
    @dep_columns = columns.dup
    columns.push(@ds[@y_var])
    matrix=Matrix.columns(columns)
    @lr_s=nil
    @lr=::Alglib::LinearRegression.build_from_matrix(matrix)
    @coeffs=assign_names(@lr.coeffs)
  end
    
  def _dump(i)
    Marshal.dump({'ds'=>@ds,'y_var'=>@y_var})
  end

  def self._load(data)
    h=Marshal.load(data)
    self.new(h['ds'], h['y_var'])
  end
      
  def coeffs
    @coeffs
  end
  # Coefficients using a constant
  # Based on http://www.xycoon.com/ols1.htm
  def matrix_resolution
    mse_p=mse
    columns=@dep_columns.dup.map {|xi| xi.map{|i| i.to_f}}
    columns.unshift([1.0]*@ds.cases)
    y=Matrix.columns([@dy.data.map  {|i| i.to_f}])
    x=Matrix.columns(columns)
    xt=x.t
    matrix=((xt*x)).inverse*xt
    matrix*y
  end

  def r2
    r**2
  end

  def r
    Bivariate::pearson(@dy,predicted)
  end  

  def sst
    @dy.ss
  end

  def constant
    @lr.constant
  end

  def standarized_coeffs
    l=lr_s
    assign_names(l.coeffs)
  end

  def lr_s
    if @lr_s.nil?
      build_standarized
    end
    @lr_s
  end

  def build_standarized
    @ds_s=@ds.standardize
    columns=[]
    @ds_s.vectors.each{|f|
      columns.push(@ds_s[f].to_a) unless f == @y_var
    }
    @dep_columns_s=columns.dup
    columns.push(@ds_s[@y_var])
    matrix=Matrix.columns(columns)
    @lr_s=Alglib::LinearRegression.build_from_matrix(matrix)
  end

  def process(v)
    @lr.process(v)
  end

  def process_s(v)
    lr_s.process(v)
  end
  # ???? Not equal to SPSS output
  def standarized_residuals
    res    = residuals
    red_sd = residuals.sds
    Daru::Vector.new(res.collect {|v| v.quo(red_sd) })
  end
end
end
end
end # for Statsample
end # for if

        

