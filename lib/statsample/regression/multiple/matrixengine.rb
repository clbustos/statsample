module Statsample
module Regression
module Multiple
  # Pure Ruby Class for Multiple Regression Analysis, based on a covariance or correlation matrix.
  #
  # Use Statsample::Regression::Multiple::RubyEngine if you have a 
  # Dataset, to avoid setting all details.
  # 
  # <b>Remember:</b> NEVER use a Covariance data if you have missing data. Use only correlation matrix on that case.
  #
  # 
  # Example:
  #
  #   matrix=[[1.0, 0.5, 0.2], [0.5, 1.0, 0.7], [0.2, 0.7, 1.0]]
  #   
  #   lr=Statsample::Regression::Multiple::MatrixEngine.new(matrix,2)

class MatrixEngine < BaseEngine 
  # Hash of standard deviation of predictors. 
  # Only useful for Correlation Matrix, because by default is set to 1
  attr_accessor :x_sd
  # Standard deviation of criterion
  # Only useful for Correlation Matrix, because by default is set to 1
  attr_accessor :y_sd
  # Hash of mean for predictors. By default, set to 0
  attr_accessor :x_mean
  
  # Mean for criteria. By default, set to 0
  attr_accessor :y_mean
  
  # Number of cases
  attr_writer :cases
  attr_writer :digits
  # Create object
  #
  def initialize(matrix,y_var, opts=Hash.new)
    matrix.extend Statsample::CovariateMatrix
    raise "#{y_var} variable should be on data" unless matrix.fields.include? y_var
    if matrix._type==:covariance
      @matrix_cov=matrix
      @matrix_cor=matrix.correlation
      @no_covariance=false
    else
      @matrix_cor=matrix
      @matrix_cov=matrix
      @no_covariance=true
    end
    
    @y_var=y_var
    @fields=matrix.fields-[y_var]
    
    @n_predictors=@fields.size
    @predictors_n=@n_predictors
    @matrix_x= @matrix_cor.submatrix(@fields)
    @matrix_x_cov= @matrix_cov.submatrix(@fields)
    raise LinearDependency, "Regressors are linearly dependent" if @matrix_x.determinant<1e-15

    
    @matrix_y = @matrix_cor.submatrix(@fields, [y_var])
    @matrix_y_cov = @matrix_cov.submatrix(@fields, [y_var])
    
    @y_sd=Math::sqrt(@matrix_cov.submatrix([y_var])[0,0])
    
    @x_sd=@n_predictors.times.inject({}) {|ac,i|
      ac[@matrix_x_cov.fields[i]]=Math::sqrt(@matrix_x_cov[i,i])
      ac;
    }
    
    @cases=nil
    @x_mean=@fields.inject({}) {|ac,f|
      ac[f]=0.0
      ac;
    }
    
    @y_mean=0.0
    @name=_("Multiple reggresion of %s on %s") % [@fields.join(","), @y_var]
    
    opts_default = {:digits=>3}
    opts         = opts_default.merge opts
    opts.each{|k,v|
        self.send("#{k}=",v) if self.respond_to? k
    }
      result_matrix=@matrix_x_cov.inverse * @matrix_y_cov

    if matrix._type == :covariance
      @coeffs=result_matrix.column(0).to_a
      @coeffs_stan=coeffs.collect {|k,v|
        coeffs[k]*@x_sd[k].quo(@y_sd)
      }
    else
      @coeffs_stan=result_matrix.column(0).to_a
      @coeffs=standarized_coeffs.collect {|k,v|
        standarized_coeffs[k]*@y_sd.quo(@x_sd[k])
      } 
    end
    @total_cases=@valid_cases=@cases
  end
  def cases
    raise "You should define the number of valid cases first" if @cases.nil?
    @cases
  end
  # Get R^2 for the regression
  # For fixed models is the coefficient of determination.
  # On random models, is the 'squared-multiple correlation'
  # Equal to 
  # * 1-(|R| / |R_x|) or
  # * Sum(b_i*r_yi) <- used
  def r2
    @n_predictors.times.inject(0) {|ac,i| ac+@coeffs_stan[i]* @matrix_y[i,0]} 
  end
  # Multiple correlation, on random models.
  def r
    Math::sqrt(r2)
  end
  # Value of constant
  def constant
    c = coeffs
    @y_mean - @fields.inject(0) { |a,k| a + (c[k] * @x_mean[k])}
  end
  # Hash of b or raw coefficients
  def coeffs
    assign_names(@coeffs)
  end
  # Hash of beta or standarized coefficients

  def standarized_coeffs
    assign_names(@coeffs_stan)
  end
  # Total sum of squares
  def sst
    @y_sd**2*(cases-1.0)
  end
  
  # Degrees of freedom for regression
  def df_r
    @n_predictors
  end
  # Degrees of freedom for error
  def df_e
    cases-@n_predictors-1
  end
  # Tolerance for a given variable
  # defined as (1-R^2) of regression of other independent variables
  # over the selected
  # == Reference:
  # * http://talkstats.com/showthread.php?t=5056
  def tolerance(var)
    return 1 if @matrix_x.column_size==1
    lr=Statsample::Regression::Multiple::MatrixEngine.new(@matrix_x, var)
    1-lr.r2
  end
  # Standard Error for coefficients.
  # Standard error of a coefficients depends on
  # * Tolerance of the coeffients: Higher tolerances implies higher error
  # * Higher r2 implies lower error
  # == Reference:
  # * Cohen et al. (2003). Applied Multiple Reggression / Correlation Analysis for the Behavioral Sciences
  #
  def coeffs_se
    out={}
    #mse=sse.quo(df_e)
    coeffs.each {|k,v|
      out[k]=@y_sd.quo(@x_sd[k])*Math::sqrt( 1.quo(tolerance(k)))*Math::sqrt((1-r2).quo(df_e))
    }
    out
  end
  # t value for constant
  def constant_t
    return nil if constant_se.nil?
    constant.to_f / constant_se
  end
  # Standard error for constant.
  # This method recreates the estimaded variance-covariance matrix
  # using means, standard deviation and covariance matrix.
  # So, needs the covariance matrix.
  def constant_se
    return nil if @no_covariance
    means=@x_mean
    #means[@y_var]=@y_mean
    means[:constant]=1
    sd=@x_sd
    #sd[@y_var]=@y_sd
    sd[:constant]=0
    fields=[:constant]+@matrix_cov.fields-[@y_var]
    # Recreate X'X using the variance-covariance matrix
    xt_x=::Matrix.rows(fields.collect {|i|
      fields.collect {|j|
        if i==:constant or j==:constant
          cov=0
        elsif i==j
          cov=sd[i]**2
        else
          cov=@matrix_cov.submatrix(i..i,j..j)[0,0]
        end
        cov*(@cases-1)+@cases*means[i]*means[j]
      }
    })
    matrix=xt_x.inverse * mse
    matrix.collect {|i| Math::sqrt(i) if i>0 }[0,0]
  end
  
end
end
end
end
