#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

require 'statsample'
require 'mathn'


Statsample::Analysis.store(Statsample::Regression::Multiple::MultipleDependent) do
  
  complete=Matrix[
  [1,0.53,0.62,0.19,-0.09,0.08,0.02,-0.12,0.08],
  [0.53,1,0.61,0.23,0.1,0.18,0.02,-0.1,0.15],
  [0.62,0.61,1,0.03,0.1,0.12,0.03,-0.06,0.12],
  [0.19,0.23,0.03,1,-0.02,0.02,0,-0.02,-0.02],
  [-0.09,0.1,0.1,-0.02,1,0.05,0.06,0.18,0.02],
  [0.08,0.18,0.12,0.02,0.05,1,0.22,-0.07,0.36],
  [0.02,0.02,0.03,0,0.06,0.22,1,-0.01,-0.05],
  [-0.12,-0.1,-0.06,-0.02,0.18,-0.07,-0.01,1,-0.03],
  [0.08,0.15,0.12,-0.02,0.02,0.36,-0.05,-0.03,1]]
  
  complete.extend Statsample::CovariateMatrix
  complete.fields=%w{adhd cd odd sex age monly mwork mage poverty}
  
  lr=Statsample::Regression::Multiple::MultipleDependent.new(complete, %w{adhd cd odd})
  
  echo "R^2_yx #{lr.r2yx}"
  echo "P^2_yx #{lr.p2yx}"
end


if __FILE__==$0
   Statsample::Analysis.run_batch
end
