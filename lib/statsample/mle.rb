module Statsample
    # Maximum Likehood Estimation
    # Multiple classes for estimate mle for a model
    # Based 
    module MLE
        ITERATIONS=20
        # Newton Raphson without automatic stopping criteria.
        # 
        # Source: Maximum Likelihood Estimation With Java and Ruby
        # Author: Peter von Tessin
        # Date: November 6, 2005
        # 
        # <tt>x</tt>: matrix of dependent variables. Should have nxk dimensions
        # <tt>y</tt>: matrix of independent values. Should have nx1 dimensions
        # <tt>model</tt>: class for modeling. Could be Normal or Logit
        # <tt>start_values</tt>: matrix of coefficients. Should have 1xk dimensions
        def self.newton_raphson(x,y,model, start_values=nil)
            # deep copy?
            if start_values=nil?
                fd=[]
                x.column_size.times{|i| fd[i]=[0.0]}
                parameters = Matrix[fd]
            else
                parameters = start_values.dup
            end
            
            raise "n on y != n on x" if x.row_size!=y.row_size
            raise "k on x != k on start_values" if x.column_size!=start_values.column_size
            ITERATIONS.times do
                h = model.second_derivative(x,y,parameters)
                if h.singular?
                    puts "Hessian is singular!"
                end
                fd = model.first_derivative(x,y,parameters)
                parameters = parameters-(h.inverse*(fd))
            end
            parameters
        end

    end
end
