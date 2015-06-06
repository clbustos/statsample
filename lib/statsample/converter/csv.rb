# This module will be removed in the next release.
# Please shift to using Daru::DataFrame.from_csv and #write_csv for CSV
# related operations.
module Statsample
  class CSV
    class << self
      # Return a DataFrom created from a csv file.
      #
      # == NOTE
      # 
      # This method has been DEPRECATED in favour of Daru::DataFrame.from_csv.
      # Please switch to using that.
      def read(filename, empty = [''], ignore_lines = 0, opts = {})
        raise NoMethodError, "Deprecated. Use Daru::DataFrame.from_csv instead."
      end

      # Save a Dataset on a csv file.
      #
      # == NOTE
      # 
      # This method has BEEN DEPRECATED in favor of Daru::DataFrame#write_csv.
      # Please use that instead.
      def write(dataset, filename, convert_comma = false, opts = {})
        raise NoMethodError, "Deprecated. Use Daru::DataFrame#write_csv instead."
      end
    end
  end
end
