require 'GDChart'
module Statsample
	module Util
	class << self
		def chart_gdchart(file,width,height,chart_type, labels, options,num_datasets,data)
				require 'GDChart'
				gdc=GDChart.new
				gdc.title="Generic title"
				gdc.bg_color=0xFFFFFF
				gdc.image_type=GDChart::JPEG
				options.each{|k,v|
					gdc.send(k+"=",v)
				}
				f=File.open(file,"w") {|f|
					gdc.out_graph(width,height,f,chart_type, data.length/num_datasets,labels,num_datasets,data)
				}
		end
		end
	end
	class Vector
		# Creates a barchart using ruby-gdchart
		def gdchart_frequencies(file, width=300, height=150, chart_type=GDChart::BAR, options={})
			labels,data=[],[]
			self.frequencies.sort.each{|k,v|
				labels.push(k.to_s)
				data.push(v) 
			}
			options['ext_color']=[0xFF3399,0xFF9933,0xFFEE33,0x33FF33, 0x9966FF]
			Statsample::Util.chart_gdchart(file,width,height,chart_type, labels,options,1,data)
		end
		def gdchart_histogram(bins,file, width=300, height=150, chart_type=GDChart::BAR, options={})
            check_type :scale
            labels=[]
            h=histogram(bins)
            data=[]
            (0...bins).each{|bin|
                data.push(h[bin])
                range=h.get_range(bin)
                labels.push(((range[0]+range[1]) / 2.to_f).to_s)
            }
            Statsample::Util.chart_gdchart(file, width, height, chart_type, labels,options, 1,data)
		end
	end
end
