module Statsample
  module Regression
    module Binomial
      # Create a Logit model object.
      # ds:: Dataset
      # y::  Name of dependent vector
      # Use
      #   dataset=Statsample::CSV.read("data.csv")
      #   y="y" 
      #   lr=Statsample::Regression::Binomial.logit(dataset,y)
      #   
      def self.logit(ds,y_var)
        Logit.new(ds,y_var)                
      end
      # Create a Probit model object.
      # ds:: Dataset
      # y::  Name of dependent vector
      # Use
      #   dataset=Statsample::CSV.read("data.csv")
      #   y="y" 
      #   lr=Statsample::Regression::Binomial.probit(dataset,y)
      #   
      
      def self.probit(ds,y_var)
        Probit.new(ds,y_var)                
      end
      # Base Engine for binomial regression analysis.
      # See Statsample::Regression::Binomial.logit() and
      # Statsample::Regression::Binomial.probit for fast
      # access methods.
      # 
      # Use:
      #   dataset=Statsample::CSV.read("data.csv")
      #   y="y" 
      #   model=Statsample::MLE::Logit.new
      #   lr=Statsample::Regression::Binomial::BaseEngine(dataset, y, model)
    class BaseEngine
      attr_reader :log_likehood, :iterations
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
      # Constant value
      def constant
        @coeffs['_constant']
      end
      # Regression coefficients
      def coeffs
        c=@coeffs.dup
        c.delete("_constant")
        c
      end
      # Constant standard error
      def constant_se
        i=@fields.index :_constant
        Math::sqrt(@var_cov_matrix[i,i])
      end
      def assign_names(c)
        a={}
        @fields.each_index do |i|
          a[@fields[i]]=c[i]
        end
        a
      end
      end # Base Engine
    end # Dichotomic
  end # Regression
end # Stasample
