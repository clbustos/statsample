module Statsample
    module Regression
        module Binomial
            # Logistic Regression
            class Probit < BaseEngine
                def initialize(ds,y_var)
                    model=Statsample::MLE::Probit.new
                    super(ds,y_var,model)
                end
            end
        end
    end
end