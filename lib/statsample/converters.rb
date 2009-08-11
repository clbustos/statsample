module Statsample
    # Create and dumps Datasets on a database
	module Database
        require 'dbi'
		class << self
        # Read a database query and returns a Dataset
        #
        # USE:
        #
        #  dbh = DBI.connect("DBI:Mysql:database:localhost", "user", "password")
        #  Statsample.read(dbh, "SELECT * FROM test")
        #
        def read(dbh,query)
            sth=dbh.execute(query)
            vectors={}
            fields=[]
            sth.column_info.each {|c|
                vectors[c['name']]=Statsample::Vector.new([])
                vectors[c['name']].type= (c['type_name']=='INTEGER' or c['type_name']=='DOUBLE') ? :scale : :nominal
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
        def insert(ds, dbh,table)
            query="INSERT INTO #{table} ("+ds.fields.join(",")+") VALUES ("+((["?"]*ds.fields.size).join(","))+")"
            sth=dbh.prepare(query)
            ds.each_array{|c|
                sth.execute(*c)
            }
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
                    dataset.each {|row|
                        values=dataset.fields.collect{|f|
                            if dataset[f].is_valid? row[f]
                                row[f]
                            else
                                ""
                            end
                        }
                        fp.puts(values.join("\t"))
                    }
                end
        end
        end
    end
    class SpreadsheetBase
        class << self
            def extract_fields(row)
                fields=row.to_a.collect{|c| c.downcase}
                if fields.size!=fields.uniq.size
                    repeated=fields.inject({}) {|a,v|
                    (a[v].nil? ? a[v]=1 : a[v]+=1); a }.find_all{|k,v| v>1}.collect{|k,v|k}.join(",")
                    raise "There are some repeated fields on the header:#{repeated}. Please, fix" 
                end
                fields
            end
            
            def process_row(row,empty)
                row.to_a.collect do |c|
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
            def convert_to_scale(ds,fields)
                fields.each do |f|
                    if ds[f].can_be_scale?
                        ds[f].type=:scale
                    end
                end
            end
                
        end
    end
    class Excel < SpreadsheetBase 
        class << self
            def write(dataset,filename)
                require 'spreadsheet'
                book = Spreadsheet::Workbook.new
                sheet = book.create_worksheet
                format = Spreadsheet::Format.new :color => :blue,
                                   :weight => :bold
                sheet.row(0).concat(dataset.fields)
                sheet.row(0).default_format = format
                i=1
                dataset.each_array{|row|
                    sheet.row(i).concat(row)
                    i+=1
                }
                book.write(filename)
            end
            # Returns a dataset based on a xls file
            # USE:
            #     ds = Statsample::Excel.read("test.xls")
            #
            def read(filename, worksheet_id=0, ignore_lines=0, empty=[''])
            require 'spreadsheet'
                first_row=true
                fields=[]
                fields_data={}
                ds=nil
                line_number=0
                book = Spreadsheet.open filename
                sheet= book.worksheet worksheet_id
                sheet.each do |row|
                    line_number+=1
                    if(line_number<=ignore_lines)
                        #puts "Skip line"
                        next
                    end
                    # This should be fixed.
                    # If we have a Formula, should be resolver first
                    row.collect!{|c|
                        if c.is_a? Spreadsheet::Formula
                            nil
                        else
                            c
                        end
                    }
                    if first_row
                        fields=extract_fields(row)
                        ds=Statsample::Dataset.new(fields)
                        first_row=false
                    else
                        rowa=process_row(row,empty)
                        (fields.size - rowa.size).times {|i|
                            rowa << nil
                        }
                        ds.add_case(rowa,false)
                    end
                end
                convert_to_scale(ds,fields)
                ds.update_valid_data
                ds
            end
        end
    end
    class CSV < SpreadsheetBase
		class << self
        # Returns a Dataset  based on a csv file
        #
        # USE:
        #     ds=Statsample::CSV.read("test_csv.csv")
        def read(filename, empty=[''],ignore_lines=0,fs=nil,rs=nil)
        require 'csv'
                first_row=true
                fields=[]
                fields_data={}
                ds=nil
                line_number=0
                ::CSV.open(filename,'r',fs,rs) do |row|
                    line_number+=1
                    if(line_number<=ignore_lines)
                        #puts "Skip line"
                        next
                    end
                    row.collect!{|c|
                        c.to_s
                    }
                    if first_row
                        fields=extract_fields(row)
                        ds=Statsample::Dataset.new(fields)
                        first_row=false
                    else
                        rowa=process_row(row,empty)
                        ds.add_case(rowa,false)
                    end
                end
                convert_to_scale(ds,fields)
                ds.update_valid_data
                ds
            end
        # Save a Dataset on a csv file
        #
        # USE:
        #     Statsample::CSV.write(ds,"test_csv.csv")            
        def write(dataset,filename, convert_comma=false,*opts)
                writer=::CSV.open(filename,'w',*opts)
                writer << dataset.fields
                dataset.each_array{|row|
                    if(convert_comma)
                        row.collect!{|v| v.to_s.gsub(".",",")}
                    end
                    writer << row
                }
                writer.close
            end
		end
    end
    module Mx
        class << self
            def write(dataset,filename,type=:covariance)
            puts "Writing MX File"
            File.open(filename,"w") {|fp|
                fp.puts "! #{filename}"
                fp.puts "! Output generated by Statsample"
                fp.puts "Data Ninput=#{dataset.fields.size} Nobservations=#{dataset.cases}"
                fp.puts "Labels "+dataset.fields.join(" ")
                case type
                when :raw
                    fp.puts "Rectangular"
                    dataset.each {|row|
                        out=dataset.fields.collect {|f|
                            if dataset[f].is_valid? row[f]
                                row[f]
                            else
                                "."
                            end
                        }
                        fp.puts out.join("\t")
                    }
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
            }
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
				default_opt = {:dataname => "Default", :description=>""}
				default_opt.merge! opt
				carrier=OpenStruct.new
				carrier.categorials=[]
				carrier.conversions={}
				variables_def=dataset.vectors.collect{|k,v|
					variable_definition(carrier,v,k)
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
					records << "<record>#{values_definition(c)}</record>\n"
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
<records count="#{dataset.cases}">
#{records}
</records>

</data>
</ggobidata>
EOC

out

			end
			def values_definition(c)
				c.collect{|v|
					if v.is_a? Float
						"<real>#{v}</real>"
					elsif v.is_a? Integer
						"<int>#{v}</int>"
					else
						"<string>#{v}</string>"
					end
				}.join(" ")
			end
			# Outputs a string for a variable definition
			# v = vector
			# name = name of the variable
			# nickname = nickname
			def variable_definition(carrier,v,name,nickname=nil)
				nickname = (nickname.nil? ? "" : "nickname=\"#{nickname}\"" )
				if v.type==:nominal or v.data.find {|d|  d.is_a? String }
					carrier.categorials.push(name)
					carrier.conversions[name]={}
					factors=v.data.uniq.sort
					out ="<categoricalvariable name=\"#{name}\" #{nickname}>\n"
					out << "<levels count=\"#{factors.size}\">\n"
					out << (1..factors.size).to_a.collect{|i|
						carrier.conversions[name][factors[i-1]]=i
						"<level value=\"#{i}\">#{v.labeling(factors[i-1])}</level>"
					}.join("\n")
					out << "</levels>\n</categoricalvariable>\n"
					out
				elsif v.data.find {|d| d.is_a? Float}
					"<realvariable name=\"#{name}\" #{nickname} />"
				else
					"<integervariable name=\"#{name}\" #{nickname} />"
				end
			end

		end
	end
end
