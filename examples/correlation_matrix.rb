#!/usr/bin/ruby

# == Description
# 
# Creating and summarizing a correlation matrix with daru and statsample
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
Statsample::Analysis.store("Statsample::Bivariate.correlation_matrix") do
  # Create a Daru::DataFrame containing 4 vectors a, b, c and d.
  #
  # Notice that the `clone` option has been set to *false*. This tells Daru
  # to not clone the Daru::Vectors being supplied by `rnorm`, since it would
  # be unnecessarily counter productive to clone the vectors once they have
  # been assigned to the dataframe.
  samples=1000
  ds = Daru::DataFrame.new({
    :a => rnorm(samples),
    :b => rnorm(samples),
    :c => rnorm(samples),
    :d => rnorm(samples)
  }, clone: false)

  # Calculate correlation matrix by calling the `cor` shorthand.
  cm = cor(ds)
  summary(cm)
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end

