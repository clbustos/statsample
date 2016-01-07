#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib')
require 'statsample'

Statsample::Analysis.store(Statsample::Test::ChiSquare) do
  # Collect the two vectors with the categorical data (raw number of occurences) into one matrix. Here
  #--------------------------------------------
  #| category | observation 1 | observation 2 |
  #|------------------------------------------|
  #|    A     |      100      |      20       |
  #|    B     |      50       |      70       |
  #|    C     |      30       |      100      |
  #|------------------------------------------|
  #
  m=Matrix[[100, 50, 30],[20, 70, 100]]
  x_2=Statsample::Test.chi_square(m)
  # after the test is done, look at the p-value.
  puts x_2.probability
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end
