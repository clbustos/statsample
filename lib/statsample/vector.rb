module Statsample::VectorShorthands
  # Creates a new Statsample::Vector object
  # Argument should be equal to Vector.new
  def to_vector(*args)
    Daru::Vector.new(self)
  end
end

class Array
  include Statsample::VectorShorthands
end

if Statsample.has_gsl?
  module GSL
    class Vector
      include Statsample::VectorShorthands
    end
  end
end
