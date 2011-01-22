require(File.expand_path(File.dirname(__FILE__)+'/helpers_benchmark.rb'))

extend BenchPress


name "Statsample::Factor::Map with and without GSL"
author 'Clbustos'
date '2011-01-18'
summary "Velicer's MAP uses a lot of Matrix algebra. How much we can improve the timing using GSL?
"

reps 20 #number of repetitions

m=Matrix[ 
        [ 1, 0.846, 0.805, 0.859, 0.473, 0.398, 0.301, 0.382],
        [ 0.846, 1, 0.881, 0.826, 0.376, 0.326, 0.277, 0.415],
        [ 0.805, 0.881, 1, 0.801, 0.38, 0.319, 0.237, 0.345],
        [ 0.859, 0.826, 0.801, 1, 0.436, 0.329, 0.327, 0.365],
        [ 0.473, 0.376, 0.38, 0.436, 1, 0.762, 0.73, 0.629],
        [ 0.398, 0.326, 0.319, 0.329, 0.762, 1, 0.583, 0.577],
        [ 0.301, 0.277, 0.237, 0.327, 0.73, 0.583, 1, 0.539],
        [ 0.382, 0.415, 0.345, 0.365, 0.629, 0.577, 0.539, 1]
  ]
  
map=Statsample::Factor::MAP.new(m)


measure "Statsample::Factor::MAP without GSL" do
  map.use_gsl=false
  map.compute
end

measure "Statsample::Factor::MAP with GSL" do
  map.use_gsl=true
  map.compute
end

