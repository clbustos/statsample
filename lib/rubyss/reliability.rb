module RubySS
	module Reliability
		class << self
            # Calculate Chonbach's alpha for a given dataset.
            # only uses tuples without missing data
			def cronbach_alpha(ods)
				ds=ods.dup_only_valid
				n_items=ds.fields.size
				sum_var_items=ds.vectors.inject(0) {|ac,v|
					ac+v[1].variance_sample
				}
				total=ds.vector_sum
				(n_items / (n_items-1).to_f) * (1-(sum_var_items/ total.variance_sample))
			end
            # Calculate Chonbach's alpha for a given dataset
            # using standarized values for every vector.
            # Only uses tuples without missing data

            def cronbach_alpha_standarized(ods)
                ds=ods.fields.inject({}){|a,f|
                    a[f]=ods[f].vector_standarized
                    a
                }.to_dataset
                cronbach_alpha(ds)
            end
		end
        
		class ItemCharacteristicCurve
            attr_reader :totals, :counts,:vector_total
            def initialize (ds, vector_total=nil)
                vector_total||=ds.vector_sum
                raise "Total size != Dataset size" if vector_total.size!=ds.cases
                @vector_total=vector_total
                @ds=ds
                @totals={}
                @counts=@ds.fields.inject({}) {|a,v| a[v]={};a}
                process
            end
            def process
                i=0
                @ds.each{|row|
					tot=@vector_total[i]
                   @totals[tot]||=0
                   @totals[tot]+=1
					@ds.fields.each {|f|
                        item=row[f].to_s
                       @counts[f][tot]||={}
                       @counts[f][tot][item]||=0
                       @counts[f][tot][item] += 1 
					}
					i+=1
				}
            end
            def curve_field(field, item)
                out={}
                item=item.to_s
                @totals.each{|value,n|
                    count_value= @counts[field][value][item].nil? ? 0 : @counts[field][value][item] 
                    out[value]=count_value.to_f/n.to_f
                }
                out
            end
        end
		class ItemAnalysis
            attr_reader :mean, :sd,:valid_n, :alpha , :alpha_standarized
			def initialize(ds)
				@ds=ds.dup_only_valid
				@total=@ds.vector_sum
				@mean=@total.mean
                @median=@total.median
                @skew=@total.skew
                @kurtosis=@total.kurtosis
				@sd=@total.sdp
				@valid_n=@total.size
                begin
				@alpha=RubySS::Reliability.cronbach_alpha(ds)
				@alpha_standarized=RubySS::Reliability.cronbach_alpha_standarized(ds)
                rescue => e
                    raise DatasetException.new(@ds,e), "Problem on calculate alpha" 
                end
			end
            # Returns a hash with structure
			def item_characteristic_curve
				i=0
				out={}
                total={}
				@ds.each{|row|
					tot=@total[i]
					@ds.fields.each {|f|
						out[f]||= {}
                        total[f]||={}
						out[f][tot]||= 0
                        total[f][tot]||=0
						out[f][tot]+= row[f] 
                        total[f][tot]+=1
					}
					i+=1
				}
                total.each{|f,var|
                    var.each{|tot,v|
                        out[f][tot]=out[f][tot].to_f / total[f][tot]
                    }
                }
                out
			end
            def gnuplot_item_characteristic_curve(directory, base="crd",options={})
                require 'gnuplot'

                crd=item_characteristic_curve
                @ds.fields.each {|f|
                    x=[]
                    y=[]
                Gnuplot.open do |gp|
                Gnuplot::Plot.new( gp ) do |plot|
                    crd[f].sort.each{|tot,prop|
                       x.push(tot)
                       y.push((prop*100).to_i.to_f/100)
                   }
                plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
                ds.with = "linespoints"
                ds.notitle
                end

                end
                end
            }
            
            end
            def svggraph_item_characteristic_curve(directory, base="icc",options={})
                require 'rubyss/graph/svggraph'
                crd=ItemCharacteristicCurve.new(@ds)
               @ds.fields.each {|f|
                   factors=@ds[f].factors.sort
                   options={
                           :height=>500,
                           :width=>800,
                           :key=>true
                   }.update(options)
                   graph = ::SVG::Graph::Plot.new(options)
                   factors.each{|factor|
                       factor=factor.to_s
                       dataset=[]
                           crd.curve_field(f, factor).each{|tot,prop|
                               dataset.push(tot)
                               dataset.push((prop*100).to_i.to_f/100)
                            }
                        graph.add_data({
                                :title=>"#{factor}",
                               :data=>dataset
                        })
                   }
                   File.open(directory+"/"+base+"_#{f}.svg","w") {|fp|
                       fp.puts(graph.burn())
                   }
               }
               
           end
			def item_total_correlation
				@ds.fields.inject({}) do |a,v|
					vector=@ds[v].dup
					ds2=@ds.dup
					ds2.delete_vector(v)
					total=ds2.vector_sum
					a[v]=RubySS::Bivariate.pearson(vector,total)
					a
				end
			end
			def item_statistics
				@ds.fields.inject({}) do |a,v|
					a[v]={:mean=>@ds[v].mean,:sds=>@ds[v].sds}
					a
				end
			end
			
			def stats_if_deleted
				@ds.fields.inject({}){|a,v|
					ds2=@ds.dup
					ds2.delete_vector(v)
					total=ds2.vector_sum
					a[v]={}
					a[v][:mean]=total.mean
					a[v][:sds]=total.sds
					a[v][:variance_sample]=total.variance_sample
					a[v][:alpha]=RubySS::Reliability.cronbach_alpha(ds2)
					a
				}
			end
			def html_summary
				html = <<EOF
<p><strong>Summary for scale:</strong></p>
<ul>
<li>Mean=#{@mean}</li>
<li>Std.Dv.=#{@sd}</li>
<li>Median=#{@median}</li>
<li>Skewness=#{sprintf("%0.3f",@skew)}</li>
<li>Kurtosis=#{sprintf("%0.3f",@kurtosis)}</li>

<li>Valid n:#{@valid_n}</li>
<li>Cronbach alpha: #{@alpha}</li>
</ul>
<table><thead><th>Variable</th>

<th>Mean</th>
<th>StDv.</th>
<th>Mean if deleted</th><th>Var. if
deleted</th><th>	StDv. if
deleted</th><th>	Itm-Totl
Correl.</th><th>Alpha if
deleted</th></thead>
EOF

itc=item_total_correlation
sid=stats_if_deleted
is=item_statistics
@ds.fields.each {|f|
	html << <<EOF
<tr>
	<td>#{f}</td>
    <td>#{sprintf("%0.5f",is[f][:mean])}</td>
    <td>#{sprintf("%0.5f",is[f][:sds])}</td>
	<td>#{sprintf("%0.5f",sid[f][:mean])}</td>
	<td>#{sprintf("%0.5f",sid[f][:variance_sample])}</td>
	<td>#{sprintf("%0.5f",sid[f][:sds])}</td>
	<td>#{sprintf("%0.5f",itc[f])}</td>
	<td>#{sprintf("%0.5f",sid[f][:alpha])}</td>
</tr>
EOF
}
html << "</table><hr />"
html
			end
		end		
		
	end
end
