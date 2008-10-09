module RubySS
    # Create and dumps Datasets on a database
	module Database
        require 'dbi'
		class << self
        # Read a database query and returns a Dataset
        #
        # USE:
        #
        #  dbh = DBI.connect("DBI:Mysql:database:localhost", "user", "password")
        #  RubySS.read(dbh, "SELECT * FROM test")
        #
        def read(dbh,query)
            sth=dbh.execute(query)
            vectors={}
            fields=[]
            sth.column_info.each {|c|
                vectors[c['name']]=RubySS::Vector.new([])
                vectors[c['name']].type= (c['type_name']=='INTEGER') ? :scale : :nominal
                fields.push(c['name'])
            }
            ds=RubySS::Dataset.new(vectors,fields)
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
        #  RubySS.insert(ds,dbh,"test")
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
        # RubySS.create_sql(ds,"test")
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
    module CSV
        require 'csv'
		class << self
        # Returns a Dataset  based on a csv file
        #
        # USE:
        #     ds=RubySS::CSV.read("test_csv.csv")
        def read(filename)
                first_row=true
                fields=[]
                fields_data={}
                ds=nil
                ::CSV.open(filename,'r') do |row|
                    row.collect!{|c|
                        c.to_s
                    }
                    if first_row
                        fields=row.to_a.collect{|c| c.downcase}
                        if fields.size!=fields.uniq.size
                            raise "There are some repeated fields on the header. Please, fix" 
                        end
                        ds=RubySS::Dataset.new(fields)
                        first_row=false
                    else
                        ds.add_case(row.to_a,false)
                    end
                end
                ds.update_valid_data
                ds
            end
        # Save a Dataset on a csv file
        #
        # USE:
        #     RubySS::CSV.write(ds,"test_csv.csv")            
            def write(dataset,filename)
                writer=::CSV.open(filename,'w')
                writer << dataset.fields
                dataset.each_array{|row|
                    writer << row
                }
                writer.close
            end
		end
    end
	module GGobi
		class << self
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
