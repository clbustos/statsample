require 'SVG/Graph/Bar'
require 'SVG/Graph/BarHorizontal'
require 'SVG/Graph/Pie'


module RubySS
	class Nominal
		# Creates a barchart using ruby-gdchart
		def svgchart_frequencies(file, width=600, height=300, chart_type=SVG::Graph::Bar, options={})
			labels,data=[],[]
			self.frequencies.sort.each{|k,v|
				labels.push(k.to_s)
				data.push(v) 
			}
            options[:height]=height
            options[:width]=width
            options[:fields]=labels  
          graph = chart_type.new(options)
          graph.add_data(
            :data => data,
            :title => "Frequencies"
          )
          File.open(file,"w") {|f|
              f.puts(graph.burn)
          }
		end
	end
	class Scale < Ordinal
		def svgchart_histogram(bins,file, width=600, height=300, chart_type=SVG::Graph::Bar, options={})
            labels=[]
            h=histogram(bins)
            data=[]
            (0...bins).each{|bin|
                data.push(h[bin])
                range=h.get_range(bin)
                labels.push(((range[0]+range[1]) / 2.to_f).to_s)
            }
            options[:height]=height
            options[:width]=width
            options[:fields]=labels  
            graph = chart_type.new(options)
            graph.add_data(
            :data => data,
            :title => "Bins"
            )
            File.open(file,"w") {|f|
              f.puts(graph.burn)
            }
            
            
            
		end
	end
end
