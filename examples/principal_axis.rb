#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'

Statsample::Analysis.store(Statsample::Factor::PrincipalAxis) do

  matrix=Matrix[
  [1.0, 0.709501601093587, 0.877596585880047, 0.272219316266807],  [0.709501601093587, 1.0, 0.291633797330304, 0.871141831433844], [0.877596585880047, 0.291633797330304, 1.0, -0.213373722977167], [0.272219316266807, 0.871141831433844, -0.213373722977167, 1.0]]
  
  matrix.extend Statsample::CovariateMatrix
  
  #matrix.fields=%w{a b c d}
  fa=principal_axis(matrix,:m=>1,:smc=>false)
  
  summary fa
end

if __FILE__==$0
   Statsample::Analysis.run_batch
end

