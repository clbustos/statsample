require File.dirname(__FILE__)+"/../lib/statsample"
require 'statsample/dataset'
require 'gnuplot'


ds=Statsample::Dataset.new({'v1'=>[1,2,3,4,5,6,7,8,1,2,3,4,5,6,7,8].to_vector(:scale), 'v2'=>[10,20,10,50,40,20,10,20,10,20,10,50,20,20,10,20].to_vector(:scale), 'v3'=>[5,10,30,20,10,12,21,32,5,10,30,20,10,12,21,32].to_vector(:scale)})
p ds['v2'].frequencies
ds['v2'].plot_histogram

