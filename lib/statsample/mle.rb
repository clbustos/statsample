require 'statsample/mle/normal'
require 'statsample/mle/logit'
require 'statsample/mle/probit'
require 'mathn'
module Statsample
    # Maximum Likehood Estimation
    # Multiple classes for estimate mle for a model
    # Based 
    module MLE
        ITERATIONS=100
        MIN_DIFF=1e-5
        def self.mle(model,x,y,b)
            prod=1
            x.row_size.times{|i|
                xi=Matrix.rows([x.row(i).to_a.collect{|v| v.to_f}])
                y_val=y[i,0].to_f
                fbx=model.f(b,x)
                prod=prod*model.mle(xi,y_val,b)
            }
            prod
        end
        def self.ln_mle(model,x,y,b)
            return model.total_ln_mle(x,y,b) if model.respond_to? :total_ln_mle
            sum=0
            x.row_size.times{|i|
                xi=Matrix.rows([x.row(i).to_a.collect{|v| v.to_f}])
                y_val=y[i,0].to_f
                sum+=model.ln_mle(xi,y_val,b)
            }
            sum
        end
        def self.set_parameters(x,model)
            fd=[]
            k=x.column_size
            
            #k.times{|i| fd[i]=(2.0*rand()-1.0) / k.to_f}
            k.times{|i| fd[i]=0.0}

            if model==Statsample::MLE::Normal
                fd.push(0.1)
            end
            parameters = Matrix.columns([fd])
        end
        
        # Newton Raphson with automatic stopping criteria.
        # Based on: Von Tessin, P. (2005). Maximum Likelihood Estimation With Java and Ruby
        #
        # <tt>x</tt>: matrix of dependent variables. Should have nxk dimensions
        # <tt>y</tt>: matrix of independent values. Should have nx1 dimensions
        # <tt>model</tt>: class for modeling. Could be Normal or Logit
        # <tt>start_values</tt>: matrix of coefficients. Should have 1xk dimensions
        def self.newton_raphson(x,y,model, start_values=nil)
            # deep copy?
            if start_values.nil?
                parameters=set_parameters(x,model)
            else
                parameters = start_values.dup
            end
            cv=Matrix.rows([([1.0]*parameters.row_size)])
            last_diff=nil
            raise "n on y != n on x" if x.row_size!=y.row_size
            old_lmle=ln_mle(model,x,y,parameters)
            ITERATIONS.times do |i|
                h = model.second_derivative(x,y,parameters)
                if h.singular?
                    puts "Hessian is singular!"
                    return parameters
                end
                fd = model.first_derivative(x,y,parameters)
                parameters = parameters-(h.inverse*(fd))
                begin
                    new_lmle=ln_mle(model,x,y,parameters)
                    #puts "[#{i}]Log-MLE:#{new_lmle} (Diff:#{(new_lmle-old_lmle) / new_lmle})"
                    if(new_lmle < old_lmle) or ((new_lmle-old_lmle) / new_lmle).abs < MIN_DIFF
                        break;
                    end
                    old_lmle=new_lmle
                rescue =>e
                    puts "#{e}"
                    #puts "dup"
                end
                
            end
            parameters
        end

    end
end
