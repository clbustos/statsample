require(File.expand_path(File.dirname(__FILE__)+'/helpers_tests.rb'))
#require 'rserve'
#require 'statsample/rserve_extension'

class StatsampleFactorMpaTestCase < MiniTest::Unit::TestCase
  def test_map
  #fields=%w{height arm.span forearm lower.leg weight bitro.diameter chest.girth chest.width}
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
  map=Statsample::Factor::MAP.new(m,:use_gsl=>false)
  map_assertions(map)
  if Statsample.has_gsl?
    map=Statsample::Factor::MAP.new(m,:use_gsl=>true)
    map_assertions(map)
  else
    raise("MAP doesn't tested with GSL")
  end    
  end
  def map_assertions(map)
    assert_in_delta(map.minfm, 0.066445,0.00001)
    assert_equal(map.number_of_factors, 2)
    assert_in_delta(map.fm[0], 0.312475,0.00001)
    assert_in_delta(map.fm[1], 0.245121,0.00001)
    
  end

  
end

