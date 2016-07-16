require(File.expand_path(File.dirname(__FILE__) + '/helpers_tests.rb'))
require 'minitest/autorun'

describe Statsample::FitModel do
  before do
    @df = Daru::DataFrame.from_csv 'test/fixtures/df.csv'
    @df.to_category 'c', 'd', 'e'
  end
  context '#df_for_regression' do
    it 'gives correct dataframe when no interaction' do
      @formula = 'y~a+e'
      @vectors = %w[a e_B e_C y]
    
      @model = Statsample::FitModel.new @formula, @df

      @model.df_for_regression.vectors.to_a.sort.must_equal @vectors.sort
    end    
  end
end