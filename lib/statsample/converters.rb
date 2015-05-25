require 'statsample/converter/spss'
module Statsample
    # Create and dumps Datasets on a database
  module Database
    class << self
      # Read a database query and returns a Dataset
      #
      # USE:
      #
      #  dbh = DBI.connect("DBI:Mysql:database:localhost", "user", "password")
      #  Statsample.read(dbh, "SELECT * FROM test")
      #
      def read(dbh,query)
        require 'dbi'
        sth=dbh.execute(query)
        vectors={}
        fields=[]
        sth.column_info.each {|c|
            vectors[c['name']]=Statsample::Vector.new([])
            vectors[c['name']].name=c['name']
            vectors[c['name']].type= (c['type_name']=='INTEGER' or c['type_name']=='DOUBLE') ? :numeric : :object
            fields.push(c['name'])
        }
        ds=Statsample::Dataset.new(vectors,fields)
        sth.fetch do |row|
            ds.add_case(row.to_a, false )
        end
        ds.update_valid_data
        ds
      end
      # Insert each case of the Dataset on the selected table
      #
      # USE:
      #
      #  ds={'id'=>[1,2,3].to_vector, 'name'=>["a","b","c"].to_vector}.to_dataset
      #  dbh = DBI.connect("DBI:Mysql:database:localhost", "user", "password")
      #  Statsample::Database.insert(ds,dbh,"test")
      #
      def insert(ds, dbh, table)
        require 'dbi'
        query="INSERT INTO #{table} ("+ds.fields.join(",")+") VALUES ("+((["?"]*ds.fields.size).join(","))+")"
        sth=dbh.prepare(query)
        ds.each_array{|c| sth.execute(*c) }
        return true
      end
      # Create a sql, basen on a given Dataset
      #
      # USE:
      #
      #  ds={'id'=>[1,2,3,4,5].to_vector,'name'=>%w{Alex Peter Susan Mary John}.to_vector}.to_dataset
      #  Statsample::Database.create_sql(ds,'names')
      #   ==>"CREATE TABLE names (id INTEGER,\n name VARCHAR (255)) CHARACTER SET=UTF8;"
      #
      def create_sql(ds,table,charset="UTF8")
        sql="CREATE TABLE #{table} ("
        fields=ds.fields.collect{|f|
            v=ds[f]
            f+" "+v.db_type
        }
        sql+fields.join(",\n ")+") CHARACTER SET=#{charset};"
      end
    end
  end
  module Mondrian
    class << self
      def write(dataset,filename)
        File.open(filename,"wb") do |fp|
          fp.puts dataset.fields.join("\t")
          dataset.each_array_with_nils do |row|
            row2=row.collect{|v| v.nil? ? "NA" : v.to_s.gsub(/\s+/,"_") }
            fp.puts row2.join("\t")
          end
        end
      end
    end
  end
  class SpreadsheetBase
    class << self
      def extract_fields(row)
        i=0;
        fields=row.to_a.collect{|c|
          if c.nil?
            i+=1
            "var%05d" % i
          else
            c.to_s.downcase
          end
        }
        fields.recode_repeated
      end

      def process_row(row,empty)
        row.to_a.map do |c|
          if empty.include?(c)
              nil
          else
            if c.is_a? String and c.is_number?
              if c=~/^\d+$/
                c.to_i
              else
                c.gsub(",",".").to_f
              end
            else
              c
            end
          end
        end
      end
      def convert_to_numeric_and_date(ds,fields)
        fields.each do |f|
          if ds[f].can_be_numeric?
            ds[f].type=:numeric
          elsif ds[f].can_be_date?
            ds[f].type=:date
          end
        end
      end

    end
  end
    class PlainText < SpreadsheetBase
      class << self
        def read(filename, fields)
          ds = Daru::DataFrame.new({}, order: fields)
          fp = File.open(filename,"r")
          fp.each_line do |line|
            row = process_row(line.strip.split(/\s+/),[""])
            next if row == ["\x1A"]
            ds.add_row(row)
          end
          ds.update
          fields.each { |f| ds[f].rename f }
          ds
        end
      end
    end
  class Excel < SpreadsheetBase
    class << self
      # Write a Excel spreadsheet based on a dataset
      # * TODO: Format nicely date values
      def write(dataset,filename)
        require 'spreadsheet'
        book = Spreadsheet::Workbook.new
        sheet = book.create_worksheet
        format = Spreadsheet::Format.new :color => :blue,
                           :weight => :bold
        sheet.row(0).concat(dataset.vectors.to_a.map(&:to_s)) # Unfreeze strings
        sheet.row(0).default_format = format
        i = 1
        dataset.each_row { |row|
          sheet.row(i).concat(row.to_a)
          i += 1
        }
        book.write(filename)
      end
      # This should be fixed.
      # If we have a Formula, should be resolver first

      def preprocess_row(row, dates)
        i=-1
        row.collect!{|c|
          i+=1
          if c.is_a? Spreadsheet::Formula
            if(c.value.is_a? Spreadsheet::Excel::Error)
              nil
            else
              c.value
            end
          elsif dates.include? i and !c.nil? and c.is_a? Numeric
              row.date(i)
          else
              c
          end
        }
      end
      private :process_row, :preprocess_row

      # Returns a dataset based on a xls file
      # USE:
      #     ds = Statsample::Excel.read("test.xls")
      #
      def read(filename, opts=Hash.new)
        require 'spreadsheet'
        raise "options should be Hash" unless opts.is_a? Hash
        opts_default = {
          :worksheet_id => 0,
          :ignore_lines => 0,
          :empty        => ['']
        }

        opts         = opts_default.merge opts

        worksheet_id = opts[:worksheet_id]
        ignore_lines = opts[:ignore_lines]
        empty        = opts[:empty]

        first_row   = true
        fields      = []
        ds          = nil
        line_number = 0
        book        = Spreadsheet.open filename
        sheet       = book.worksheet worksheet_id
        sheet.each do |row|
          begin
            dates=[]
            row.formats.each_index{|i|
              if !row.formats[i].nil? and row.formats[i].number_format=="DD/MM/YYYY"
                dates.push(i)
              end
            }

            line_number+=1
            next if line_number <= ignore_lines
            preprocess_row(row,dates)

            if first_row
              fields = extract_fields(row)
              ds = Daru::DataFrame.new({},  order: fields.map(&:to_sym))
              first_row=false
            else
              rowa = process_row(row,empty)
              (fields.size - rowa.size).times { rowa << nil }
              ds.add_row rowa
            end
          rescue => e
            error="#{e.to_s}\nError on Line # #{line_number}:#{row.join(",")}"
            raise
          end
        end
        ds.update
        fields.map(&:to_sym).each { |f| ds[f].rename f }
        ds.rename filename 
        ds
      end
    end
  end
  module Mx
    class << self
      def write(dataset,filename,type=:covariance)
        puts "Writing MX File"
        File.open(filename,"w") do |fp|
          fp.puts "! #{filename}"
          fp.puts "! Output generated by Statsample"
          fp.puts "Data Ninput=#{dataset.fields.size} Nobservations=#{dataset.cases}"
          fp.puts "Labels "+dataset.fields.join(" ")
          case type
            when :raw
            fp.puts "Rectangular"
            dataset.each do |row|
              out=dataset.fields.collect do |f|
                if dataset[f].is_valid? row[f]
                  row[f]
                else
                  "."
                end
              end
              fp.puts out.join("\t")
            end
            fp.puts "End Rectangular"
          when :covariance
            fp.puts " CMatrix Full"
            cm=Statsample::Bivariate.covariance_matrix(dataset)
            d=(0...(cm.row_size)).collect {|row|
              (0...(cm.column_size)).collect{|col|
                cm[row,col].nil? ? "." : sprintf("%0.3f", cm[row,col])
              }.join(" ")
            }.join("\n")
            fp.puts d
          end
        end
      end
    end
  end
	module GGobi
		class << self
      def write(dataset,filename,opt={})
        File.open(filename,"w") {|fp|
          fp.write(self.out(dataset,opt))
        }
      end
			def out(dataset,opt={})
				require 'ostruct'
				default_opt = {:dataname => "Default", :description=>"", :missing=>"NA"}
				default_opt.merge! opt
				carrier=OpenStruct.new
				carrier.categorials=[]
				carrier.conversions={}
				variables_def=dataset.fields.collect{|k|
					variable_definition(carrier,dataset[k],k)
				}.join("\n")

				indexes=carrier.categorials.inject({}) {|s,c|
					s[dataset.fields.index(c)]=c
					s
				}
				records=""
				dataset.each_array {|c|
					indexes.each{|ik,iv|
						c[ik]=carrier.conversions[iv][c[ik]]
					}
					records << "<record>#{values_definition(c, default_opt[:missing])}</record>\n"
				}

out=<<EOC
<?xml version="1.0"?>
<!DOCTYPE ggobidata SYSTEM "ggobi.dtd">
<ggobidata count="1">
<data name="#{default_opt[:dataname]}">
<description>#{default_opt[:description]}</description>
<variables count="#{dataset.fields.size}">
#{variables_def}
</variables>
    <records count="#{dataset.cases}" missingValue="#{default_opt[:missing]}">
#{records}
</records>

</data>
</ggobidata>
EOC

out

			end
      def values_definition(c,missing)
        c.collect{|v|
          if v.nil?
            "#{missing}"
          elsif v.is_a? Numeric
            "#{v}"
          else
            "#{v.gsub(/\s+/,"_")}"
          end
        }.join(" ")
      end
			# Outputs a string for a variable definition
			# v = vector
			# name = name of the variable
			# nickname = nickname
			def variable_definition(carrier,v,name,nickname=nil)
				nickname = (nickname.nil? ? "" : "nickname=\"#{nickname}\"" )
				if v.type==:object or v.to_a.find {|d|  d.is_a? String }
					carrier.categorials.push(name)
					carrier.conversions[name]={}
					factors=v.factors
					out ="<categoricalvariable name=\"#{name}\" #{nickname}>\n"
					out << "<levels count=\"#{factors.size}\">\n"
					out << (1..factors.size).to_a.collect{|i|
						carrier.conversions[name][factors[i-1]]=i
						"<level value=\"#{i}\">#{(v.labels[factors[i-1]] || factors[i-1])}</level>"
					}.join("\n")
					out << "</levels>\n</categoricalvariable>\n"
					out
				elsif v.to_a.find {|d| d.is_a? Float}
					"<realvariable name=\"#{name}\" #{nickname} />"
				else
					"<integervariable name=\"#{name}\" #{nickname} />"
				end
			end

		end
	end
end

require 'statsample/converter/csv.rb'

