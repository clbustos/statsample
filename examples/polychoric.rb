#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')

# == Description
# Polychoric Correlation using two-step and joint method
#
# Polychoric correlation in statsample requires installation of 
# the [statsample-bivariate-extension](https://rubygems.org/gems/statsample-bivariate-extension) 
# gem. This gem extends the Statsample::Bivariate class with useful 
# algorithms for polychoric and tetrachoric correlation.
# 
# Statsample will automatically detect presence of polychoric/tetrachoric 
# algorithms so there is no need to explicitly require the gem.
# 
# In this example we'll see how polychoric correlation can be 
# performed using statsample.
require 'statsample'
Statsample::Analysis.store(Statsample::Bivariate::Polychoric) do 
  ct=Matrix[[rand(10)+50, rand(10)+50,  rand(10)+1],
            [rand(20)+5,  rand(50)+4,   rand(10)+1],
            [rand(8)+1,   rand(12)+1,   rand(10)+1]]

  # Estimation of polychoric correlation using two-step (default)
  poly=polychoric(ct, :name=>"Polychoric with two-step", :debug=>false)
  summary poly

  # Estimation of polychoric correlation using joint method (slow)
  poly=polychoric(ct, :method=>:joint, :name=>"Polychoric with joint")
  summary poly

  # Uses polychoric series (not recomended)

  poly=polychoric(ct, :method=>:polychoric_series, :name=>"Polychoric with polychoric series")
  summary poly
end

if __FILE__==$0
   Statsample::Analysis.run_batch
end

