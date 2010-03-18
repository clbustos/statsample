module Statsample
  module Regression
    module Binomial
      # Logistic Regression class.
      # See Statsample::Regression::Binomial::BaseEngine for documentation
      class Logit < BaseEngine
        def initialize(ds,y_var)
          model=Statsample::MLE::Logit.new
          super(ds,y_var,model)
        end
      end
    end
  end
end