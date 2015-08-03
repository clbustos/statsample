require 'statsample/vector'

class Hash
  # Creates a Statsample::Dataset based on a Hash
  def to_dataframe(*args)
    Daru::DataFrame.new(self, *args)
  end

  alias :to_dataset :to_dataframe
end
