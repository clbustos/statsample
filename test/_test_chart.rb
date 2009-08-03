require File.dirname(__FILE__)+'/../lib/statsample'
require 'tempfile'
require 'test/unit'
require 'statsample/chart/gdchart'
# Not included on default test, because GDChart send a lot of warnings!
class StatsampleChartTestCase < Test::Unit::TestCase

	def initialize(*args)
		@image_path=File.dirname(__FILE__)+"/images"
		super
	end

	def test_base_chart
		file=@image_path+"/gdchart_base_bar_1.jpg"
		width=500
		height=300
		chart_type=GDChart::BAR
		labels=["a","b","c","d","e"]
		options={'set_color'=>[0xFF3399]}
		n_data=1
		data=[10,40,30,20,40]
		
		Statsample::Util.chart_gdchart(file,width,height,chart_type, labels, options,n_data,data)
		assert(File.exists?(file))
		%w{STACK_DEPTH STACK_SUM STACK_BESIDE STACK_LAYER}.each{|stack|
			file=@image_path+"/gdchart_base_bar_2_#{stack}.jpg"
			n_data=2
			options={'set_color'=>[0xFF3399,0x33FF99,0xFF99FF,0xFF3399], 'stack_type'=>GDChart.const_get(stack.intern),'title'=>"Bar #{stack}"}
	
			chart_type=GDChart::BAR
			
			data=[10,15,10,20,30,30,20,5,15,20]
			Statsample::Util.chart_gdchart(file,width,height,chart_type, labels, options,n_data,data)
			assert(File.exists?(file))
		}
	end
    def test_vector
		file=@image_path+"/gdchart_bar.jpg"
		ar=[]
		(1..1000).each {|a|
			ar.push(rand(10))
		}
		vector=ar.to_vector
		file=@image_path+"/gdchart_bar.jpg"
		vector.gdchart_frequencies(file,800,600,GDChart::BAR,'title'=>'Bar')
		assert(File.exists?(file))
		file=@image_path+"/gdchart_bar3d.jpg"
		vector.gdchart_frequencies(file,300,100,GDChart::BAR3D,'title'=>'Bar3D')
		assert(File.exists?(file))
		file=@image_path+"/gdchart_floatingbar.jpg"
		vector.gdchart_frequencies(file,200,200,GDChart::LINE,'title'=>'FloatingBar')
		assert(File.exists?(file))
		vector.type=:scale
		file=@image_path+"/gdchart_histogram.jpg"		
		vector.gdchart_histogram(5,file,300,400,GDChart::BAR,'title'=>'Histogram')
		assert(File.exists?(file))
	end
end