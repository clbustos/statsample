#!/usr/bin/ruby
$:.unshift(File.dirname(__FILE__)+'/../lib/')
# == Description
#
# This example demonstrates creation of basic Vectors and DataFrames.
require 'statsample'

Statsample::Analysis.store(Daru::DataFrame) do
  # We set lazy_update to *true* so that time is not wasted in updating
  # metdata every time an assignment happens.
  Daru.lazy_update = true

  samples = 1000

  # The 'new_with_size' function lets you specify the size of the 
  # vector as the argument and the block specifies how each element
  # of the vector will be created.
  a = Daru::Vector.new_with_size(samples) {r=rand(5); r==4 ? nil: r}
  b = Daru::Vector.new_with_size(samples) {r=rand(5); r==4 ? nil: r}

  # Pass the Daru::Vector objects in a Hash to the DataFrame constructor
  # to make a DataFrame.
  # 
  # The *order* option lets you specify the way the vectors in the Hash 
  # will be ordered. Not specifyin this will order vectors in alphabetical
  # order by default.
  ds = Daru::DataFrame.new({:a=>a,:b=>b}, order: [:b, :a])
  summary(ds)

  # Reset lazy_update to *false* to prevent other code from breaking.
  Daru.lazy_update = false
end

if __FILE__==$0
  Statsample::Analysis.run_batch
end

