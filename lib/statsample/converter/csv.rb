require 'csv'

module Statsample
  class CSV < SpreadsheetBase
    # Default options for processing CSV files. Accept the same options as
    # Ruby's `CSV#new`.
    DEFAULT_OPTIONS = {
      converters: [:numeric]
    }

    class << self
      # Return a Dataset created from a csv file.
      #
      # USE:
      #     ds = Statsample::CSV.read('test_csv.csv')
      def read(filename, empty = [''], ignore_lines = 0, opts = {})
        first_row = true
        fields = []
        ds = nil
        line_number = 0
        options = DEFAULT_OPTIONS.merge(opts)

        csv = ::CSV.open(filename, 'rb', options)

        csv.each do |row|
          line_number += 1

          if (line_number <= ignore_lines)
            next
          end

          if first_row
            fields = extract_fields(row)
            ds = Statsample::Dataset.new(fields)
            first_row = false
          else
            rowa = process_row(row, empty)
            ds.add_case(rowa, false)
          end
        end

        convert_to_scale_and_date(ds, fields)
        ds.update_valid_data
        ds
      end

      # Save a Dataset on a csv file.
      #
      # USE:
      #     Statsample::CSV.write(ds, 'test_csv.csv')
      def write(dataset, filename, convert_comma = false, opts = {})
        options = DEFAULT_OPTIONS.merge(opts)

        writer = ::CSV.open(filename, 'w', options)
        writer << dataset.fields

        dataset.each_array do |row|
          row.collect! { |v| v.to_s.gsub('.', ',') } if convert_comma
          writer << row
        end

        writer.close
      end
    end
  end
end
