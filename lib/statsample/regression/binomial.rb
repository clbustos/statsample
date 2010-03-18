module Statsample
  module Regression
    module Binomial
      # Base Engine for binomial regression analysis.
      # Use Statsample::Regression.logit and Statsample::Regression.probit 
      # for fast access methods.
      # 
      # == Usage: 
      #  dataset=Statsample::CSV.read("data.csv")
      #  y="y" 
      #  model=Statsample::MLE::Logit.new
      #  lr=Statsample::Regression::Binomial::BaseEngine(dataset, y, model)
    class BaseEngine
      attr_reader :log_likehood, :iterations
      # Parameters
      # * ds: Dataset
      # * y_var: Name of dependent variable
      # * model: One of Statsample::Regression::Binomial classes
      def initialize(ds,y_var,model) 
      @ds=ds
      @y_var=y_var
      @dy=@ds[@y_var]
      @ds_indep=ds.dup(ds.fields-[y_var])
      constant=([1.0]*ds.cases).to_vector(:scale)
      @ds_indep.add_vector("_constant",constant)
      mat_x=@ds_indep.to_matrix
      mat_y=@dy.to_matrix(:vertical)
      @fields=@ds_indep.fields
      @model=model
      coeffs=model.newton_raphson(mat_x, mat_y)
      @coeffs=assign_names(coeffs.column(0).to_a)
      @iterations=model.iterations
      @var_cov_matrix=model.var_cov_matrix
      @log_likehood=model.log_likehood(mat_x, mat_y, coeffs)
      end # init
      # Coefficients standard error
      def coeffs_se
        out={}
        @fields.each_index{|i|
            f=@fields[i]
            out[f]=Math::sqrt(@var_cov_matrix[i,i])
        }
        out.delete("_constant")
        out
      end
      # Value of constant on regression
      def constant
        @coeffs['_constant']
      end
      # Constant standard error
      def constant_se
        i=@fields.index :_constant
        Math::sqrt(@var_cov_matrix[i,i])
      end
      # Regression coefficients
      def coeffs
        c=@coeffs.dup
        c.delete("_constant")
        c
      end
      
      def assign_names(c) # :nodoc:
        a={}
        @fields.each_index do |i|
          a[@fields[i]]=c[i]
        end
        a
      end
      end # Base Engine
    end # Binomial
  end # Regression
end # Stasample
