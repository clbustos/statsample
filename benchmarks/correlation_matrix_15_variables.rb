require(File.expand_path(File.dirname(__FILE__)+'/helpers_benchmark.rb'))

extend BenchPress
cases=250
vars=20

name "gsl matrix based vs. manual ruby correlation matrix (#{vars} vars, #{cases} cases)"
author 'Clbustos'
date '2011-01-18'
summary "
A correlation matrix could be constructed using matrix algebra or
mannualy, calculating covariances, means and sd for each pair of vectors.
In this test, we test the calculation using #{vars} variables with 
#{cases} cases on each vector
"

reps 200 #number of repetitions

ds = Daru::DataFrame.new(
  vars.times.inject({}) do |ac,v|
    ac["x#{v}".to_sym]=Daru::Vector.new_with_size(cases) {rand()}
    ac
  end
)
    
measure "Statsample::Bivariate.correlation_matrix_optimized" do
  Statsample::Bivariate.correlation_matrix_optimized(ds)
end

measure "Statsample::Bivariate.correlation_matrix_pairwise" do
  Statsample::Bivariate.correlation_matrix_pairwise(ds)
end
