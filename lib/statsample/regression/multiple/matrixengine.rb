module Statsample
module Regression
module Multiple
  # Pure Ruby Class for Multiple Regression Analysis, based on a covariance or correlation matrix.
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
  # Standard deviation of criteria. 
  # Only useful for Correlation Matrix, because by default is set to 1
  
  attr_accessor :y_sd
  # Hash of mean for predictors. By default, set to 0
  # 
  attr_accessor :x_mean
  
  # Mean for criteria. By default, set to 0
  # 
  attr_accessor :y_mean
  
  # Number of cases
  attr_writer :cases
  # Create object
  #
  def initialize(matrix,y_var, opts=Hash.new)
    matrix.extend Statsample::CovariateMatrix
    raise "#{y_var} variable should be on data" unless matrix.fields.include? y_var
    
    @matrix_cor=matrix.correlation
    
    @y_var=y_var
    @fields=matrix.fields-[y_var]
    @n_predictors=@fields.size
    @matrix=matrix
    @matrix_x= matrix.submatrix(@fields)
    @matrix_y = matrix.submatrix(@fields, [y_var])
    @matrix_y_cor=@matrix_cor.submatrix(@fields, [y_var])
    @result_matrix=@matrix_x.inverse * @matrix_y
    @y_sd=Math::sqrt(@matrix.submatrix([y_var])[0,0])
    @x_sd=@matrix_x.row_size.times.inject({}) {|ac,i|
      ac[@matrix_x.fields[i]]=Math::sqrt(@matrix_x[i,i])
      ac;
    }
    @cases=nil
    @x_mean=@fields.inject({}) {|ac,f|
      ac[f]=0.0
      ac;
    }
    
    @y_mean=0.0
    @name=_("Multiple reggresion of %s on %s") % [@fields.join(","), @y_var]
    
    
    opts.each{|k,v|
        self.send("#{k}=",v) if self.respond_to? k
    }
    if matrix.type==:covariance
      @coeffs=@result_matrix.column(0).to_a
      @coeffs_stan=coeffs.collect {|k,v|
        coeffs[k]*@x_sd[k].quo(@y_sd)
      }
    else
      @coeffs_stan=@result_matrix.column(0).to_a
      
      @coeffs=standarized_coeffs.collect {|k,v|
        standarized_coeffs[k]*@y_sd.quo(@x_sd[k])
      } 
    end

  end
  def cases
    raise "You should define the number of valid cases first" if @cases.nil?
    @cases
  end
  # Get R^2 for the regression
  # Equal to 
  # * 1-(|R| / |R_x|) or
  # * Sum(b_i*r_yi)
  def r2
    #@n_predictors.times.inject(0) {|ac,i| ac+@coeffs_stan[i]* @matrix_y_cor[i,0]} 
    1-(@matrix.correlation.determinant.quo(@matrix_x.correlation.determinant))
  end
  def r
    Math::sqrt(r2)
  end
  
  def constant
    c=coeffs
    @y_mean - @fields.inject(0){|a,k| a + (c[k] * @x_mean[k])}
  end
  def coeffs
    assign_names(@coeffs)    
  end
  def standarized_coeffs
    assign_names(@coeffs_stan)
  end
  
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
  # defined as (1-r2) of regression of other independent variables
  # over the selected
  # http://talkstats.com/showthread.php?t=5056
  def tolerance(var)
    lr=Statsample::Regression::Multiple::MatrixEngine.new(@matrix_x, var)
    1-lr.r2
  end
  # Standard Error for coefficients.
  # Standard error of a coefficients depends on
  # * Tolerance of the coeffients: Higher tolerances implies higher error
  # * Higher r2 implies lower error
  
  # Reference: Cohen et al. (2003). Applied Multiple Reggression / Correlation Analysis for the Behavioral Sciences
  #
  def coeffs_se
    out={}
    mse=sse.quo(df_e)
    coeffs.each {|k,v|
      out[k]=@y_sd.quo(@x_sd[k])*Math::sqrt( 1.quo(tolerance(k)))*Math::sqrt((1-r2).quo(df_e))
    }
    out
  end
# Standard error for constant
  def constant_se
   nil
  end
  
  def to_reportbuilder(generator)
    anchor=generator.add_toc_entry(_("Multiple Regression: ")+@name)
    generator.add_html "<div class='multiple-regression'>#{@name}<a name='#{anchor}'></a>"
    c=coeffs
    generator.add_text(_("Engine: %s") % self.class)
    generator.add_text(_("Cases=%d") % [@cases])
    generator.add_text("r=#{sprintf('%0.3f',r)}")
    generator.add_text("r=#{sprintf('%0.3f',r2)}")
    
    generator.add_text(_("Equation")+"="+ sprintf('%0.3f',constant) +" + "+ @fields.collect {|k| sprintf('%0.3f%s',c[k],k)}.join(' + ') )
    
    t=ReportBuilder::Table.new(:name=>"ANOVA", :header=>%w{source ss df ms f s})
    t.add_row([_("Regression"), sprintf("%0.3f",ssr), df_r, sprintf("%0.3f",msr), sprintf("%0.3f",f), sprintf("%0.3f", significance)])
    t.add_row([_("Error"), sprintf("%0.3f",sse), df_e, sprintf("%0.3f",mse)])
  
    t.add_row([_("Total"), sprintf("%0.3f",sst), df_r+df_e])
    generator.parse_element(t)
    sc=standarized_coeffs
    cse=coeffs_se
    t=ReportBuilder::Table.new(:name=>"Beta coefficients", :header=>%w{coeff b beta se t}.collect{|field| _(field)} )
    
    if (constant_se.nil?)
      t.add_row([_("Constant"), sprintf("%0.3f", constant),"--","?","?"])
    else
      t.add_row([_("Constant"), sprintf("%0.3f", constant), "-", sprintf("%0.3f", constant_se), sprintf("%0.3f", constant_t)])
    end
    
    @fields.each do |f|
      t.add_row([f, sprintf("%0.3f", c[f]), sprintf("%0.3f", sc[f]), sprintf("%0.3f", cse[f]), sprintf("%0.3f", c[f].quo(cse[f]))])
    end  
    generator.parse_element(t)
    generator.add_html("</div>")
  end
  
  
end
end
end
end
