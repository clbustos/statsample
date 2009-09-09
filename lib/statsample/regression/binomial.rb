
module Statsample
    module Regression
        module Binomial
            def self.logit(ds,y_var)
                Logit.new(ds,y_var)                
            end
            def self.probit(ds,y_var)
                Probit.new(ds,y_var)                
            end
            
         class BaseEngine
             attr_reader :log_likehood, :iterations, :constant, :coeffs
            def initialize(ds,y_var,model)
                @ds=ds
                @y_var=y_var
                @dy=@ds[@y_var]
                @ds_indep=ds.dup(ds.fields-[y_var])
                constant=([1.0]*ds.cases).to_vector(:scale)
                @ds_indep.add_vector('_constant',constant)
                mat_x=@ds_indep.to_matrix
                mat_y=@dy.to_matrix(:vertical)
                @fields=[]
                @ds_indep.fields.each{|f|
                    if f!=@y_var
                       @fields.push(f)
                    end
                }
                @model=model
                coeffs=model.newton_raphson(mat_x, mat_y)
                @coeffs=assign_names(coeffs.column(0).to_a)
                @iterations=model.iterations
                @constant=@coeffs['_constant']
                @coeffs.delete("_constant")
                @log_likehood=model.log_likehood(mat_x, mat_y, coeffs)
                end # init
                def assign_names(c)
                        a={}
                        @fields.each_index {|i|
                            a[@fields[i]]=c[i]
                        }
                        a
                end                
            end # Base Engine
            
        end # Dichotomic
    end # Regression
end # Stasample
