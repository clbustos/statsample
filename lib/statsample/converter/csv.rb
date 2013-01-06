module Statsample
  class CSV < SpreadsheetBase
    if RUBY_VERSION<"1.9"
      require 'fastercsv'
      CSV_klass=::FasterCSV  
    else
      require 'csv'
      CSV_klass=::CSV  
    end    
    class << self

      def read19(filename,ignore_lines=0,csv_opts=Hash.new)
        #default first line is header
        csv_opts.merge!(:headers=>true, :header_converters => :symbol)
        csv = CSV_klass::Table.new(CSV_klass::read(filename,'r',csv_opts))
        csv_headers = if csv_opts[:headers]
          csv.headers
        else
          #as in R, if no header we name the headers as V1,V2,V3,V4,..
          1.upto(csv.first.length).collect { |i| "V#{i}" }
        end
        #we invert row -> column. It means csv[0] is the first column and not row. Similar to R
        csv.by_col!
        thash = {}
        csv_headers.each_with_index do |header,idx|
          thash[header] = Statsample::Vector.new(csv[idx].drop(ignore_lines))
        end
        ds=Statsample::Dataset.new(thash)
      end
      # Returns a Dataset  based on a csv file
      #
      # USE:
      #     ds=Statsample::CSV.read("test_csv.csv")
      def read(filename, empty=[''],ignore_lines=0,csv_opts=Hash.new)        
        first_row=true
        fields=[]
        fields_data={}
        ds=nil
        line_number=0
        csv=CSV_klass.open(filename,'rb', csv_opts)
        csv.each do |row|
          line_number+=1
          if(line_number<=ignore_lines)
            #puts "Skip line"
            next
          end
          row.collect!{|c| c.to_s }
          if first_row
            fields=extract_fields(row)
            ds=Statsample::Dataset.new(fields)
            first_row=false
          else
            rowa=process_row(row,empty)
            ds.add_case(rowa,false)
          end
        end
        convert_to_scale_and_date(ds,fields)
        ds.update_valid_data
        ds
      end
      # Save a Dataset on a csv file
      #
      # USE:
      #     Statsample::CSV.write(ds,"test_csv.csv")
      def write(dataset,filename, convert_comma=false,*opts)
        
        writer=CSV_klass.open(filename,'w',*opts)
        writer << dataset.fields
        dataset.each_array do|row|
          if(convert_comma)
            row.collect!{|v| v.to_s.gsub(".",",")}
          end
          writer << row
        end
        writer.close
      end
    end
  end
end
