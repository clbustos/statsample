#!/usr/bin/ruby

# == Description
# 
# Creating and summarizing a correlation matrix with daru and statsample
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
Statsample::Analysis.store("Statsample::Bivariate.correlation_matrix") do
  # It so happens that Daru::Vector and Daru::DataFrame must update metadata
  # like positions of missing values every time they are created. 
  #
  # Since we dont have any missing values in the data that we are creating, 
  # we set Daru.lazy_update = true so that missing data is not updated every
  # time and things happen much faster.
  #
  # In case you do have missing data and lazy_update has been set to *true*, 
  # you _SHOULD_ called `#update` on the concerned Vector or DataFrame object
  # everytime an assingment or deletion cycle is complete.
  Daru.lazy_update = true
  
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

  # Set lazy_update to *false* once our job is done so that this analysis does
  # not accidentally affect code elsewhere.
  Daru.lazy_update = false
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end

