module Statsample
  # Module for generic MLE calculations.
  # Use subclass of BaseMLE for specific MLE model estimation.
  # You should visit Statsample::Regression for method to perform fast
  # regression analysis. 
  # == Usage:
  # 
  #   mle=Statsample::MLE::Probit.new
  #   mle.newton_raphson(x,y)
  #   beta=mle.parameters
  #   likehood=mle.likehood(x,y,beta)
  #   iterations=mle.iterations
  # 
  module MLE
    class BaseMLE
      attr_accessor :verbose
      attr_accessor :output
      # Could be :parameters or :mle
      attr_accessor :stop_criteria
      # Variance - Covariance matrix
      attr_reader :var_cov_matrix
      # Iterations
      attr_reader :iterations
      # Parameters (beta coefficients)
      attr_reader :parameters
      ITERATIONS=100
      MIN_DIFF=1e-5
      MIN_DIFF_PARAMETERS=1e-2
      # Model should be a MLE subclass
      def initialize()
        @verbose        = false
        @output         = STDOUT
        @stop_criteria  = :parameters
        @var_cov_matrix = nil
        @iterations     = nil
        @parameters     = nil
      end
      # Calculate likehood for matrices x and y, given b parameters
      def likehood(x,y,b)
        prod=1
        x.row_size.times{|i|
          xi=Matrix.rows([x.row(i).to_a.collect{|v| v.to_f}])
          y_val=y[i,0].to_f
          fbx=f(b,x)
          prod=prod*likehood_i(xi, y_val ,b)
        }
        prod
      end
      # Calculate log likehood for matrices x and y, given b parameters
      def log_likehood(x,y,b)
        sum=0
        x.row_size.times{|i|
          xi=Matrix.rows([x.row(i).to_a.collect{|v| v.to_f}])
          y_val=y[i,0].to_f
          sum+=log_likehood_i(xi,y_val,b)
        }
        sum
      end
      
      
      # Creates a zero matrix Mx1, with M=x.M
      def set_default_parameters(x)
        fd=[0.0]*x.column_size
        fd.push(0.1)    if self.is_a? Statsample::MLE::Normal
        parameters = Matrix.columns([fd])
      end
      
      # Newton Raphson with automatic stopping criteria.
      # Based on: Von Tessin, P. (2005). Maximum Likelihood Estimation With Java and Ruby
      #
      # <tt>x</tt>:: matrix of dependent variables. Should have nxk dimensions
      # <tt>y</tt>:: matrix of independent values. Should have nx1 dimensions
      # <tt>@m</tt>:: class for @ming. Could be Normal or Logit
      # <tt>start_values</tt>:: matrix of coefficients. Should have 1xk dimensions
      def newton_raphson(x,y, start_values=nil)
        # deep copy?
        if start_values.nil?
            parameters=set_default_parameters(x)
        else
            parameters = start_values.dup
        end
        k=parameters.row_size
        cv=Matrix.rows([([1.0]*k)])
        last_diff=nil
        raise "n on y != n on x" if x.row_size!=y.row_size
        h=nil
        fd=nil
        if @stop_criteria==:mle
          old_likehood=log_likehood(x, y, parameters)
        else
          old_parameters=parameters
        end
        ITERATIONS.times do |i|
          @iterations=i+1
          puts "Set #{i}" if @verbose
          h = second_derivative(x,y,parameters)
          if h.singular?
            raise "Hessian is singular!"
          end
          fd = first_derivative(x,y,parameters)
          parameters = parameters-(h.inverse*(fd))
          
          if @stop_criteria==:parameters
          flag=true
          k.times do |j|
            diff= ( parameters[j,0] - old_parameters[j,0] ) / parameters[j,0]
            flag=false if diff.abs >= MIN_DIFF_PARAMETERS
            @output.puts "Parameters #{j}: #{diff}" if @verbose
          end
          if flag
            @var_cov_matrix = h.inverse*-1.0
            return parameters
          end
          old_parameters=parameters
          else
            begin
              new_likehood = log_likehood(x,y,parameters)
              @output.puts "[#{i}]Log-MLE:#{new_likehood} (Diff:#{(new_likehood-old_likehood) / new_likehood})" if @verbose
              if(new_likehood < old_likehood) or ((new_likehood - old_likehood) / new_likehood).abs < MIN_DIFF
                  @var_cov_matrix = h.inverse*-1.0
              #@output.puts "Ok"
                  break;
              end
              old_likehood=new_likehood
            rescue =>e
              puts "#{e}"
              #puts "dup"
            end
          end
        end
        @parameters=parameters
        parameters
      end
    end
  end
end

require 'statsample/mle/normal'
require 'statsample/mle/logit'
require 'statsample/mle/probit'
