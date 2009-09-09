module Statsample
    module Regression
        module Binomial
            # Logistic Regression
            class Logit < BaseEngine
                def initialize(ds,y_var)
                    model=Statsample::MLE::Logit.new
                    super(ds,y_var,model)
                end
            end
        end
    end
end