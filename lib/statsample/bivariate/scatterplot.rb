require 'tmpdir'
require 'rubyvis'
module Statsample
  module Bivariate
    # = Scatterplot
    # 
    # From Wikipedia:
    # A scatter plot or scattergraph is a type of mathematical diagram using
    # Cartesian coordinates to display values for two variables for a set of data.
    # 
    # The data is displayed as a collection of points, each having the value of one variable determining the position on the horizontal axis and the value of the other variable determining the position on the vertical axis.[2] This kind of plot is also called a scatter chart, scatter diagram and scatter graph.
    class Scatterplot
      include Summarizable
      attr_accessor :name
      attr_accessor :width
      attr_accessor :height
      attr_reader   :data
      def initialize(v1,v2,opts=Hash.new)
        @v1_name,@v2_name = v1.name,v2.name
        @v1,@v2           = Statsample.only_valid_clone(v1,v2)
        opts_default={
          :name=>_("Scatterplot (%s - %s)") % [@v1_name, @v2_name],
          :width=>400,
          :height=>300
        }
        @opts=opts_default.merge(opts)
        opts_default.keys.each {|k| send("#{k}=", @opts[k]) }
        @data=[]
        @v1.each_with_index {|d1,i|
          @data.push({:x=>d1,:y=>@v2[i]})
        }
      end
      def create_svg
        that=self
        #p @v1.map {|v| v}
        x=Rubyvis::Scale.linear(@v1.to_a).range(0,width)
        y=Rubyvis::Scale.linear(@v2.to_a).range(0,height)
        vis=Rubyvis::Panel.new do 
          width  that.width-40
          height that.height-25
          bottom 20
          left 20
          right 20
          top 5
          rule do
            data y.ticks
            bottom y
            stroke_style {|d| d!=0 ? "#eee" : "#000"}
            label(:anchor=>'left') do
              visible {|d| d>0 and d<that.width}
              text y.tick_format
            end
          end
          rule do
            data x.ticks
            left x
            stroke_style {|d| d!=0 ? "#eee" : "#000"}
            label(:anchor=>'bottom') do
              visible {|d| d>0 and d<that.height}
              text x.tick_format
            end
          end
          panel do
            data(that.data)
            dot do
              left {|d| x.scale(d[:x])}
              bottom {|d| y.scale(d[:y])}
              stroke_style "red"
              shape_radius 2
            end
          end
        end
        vis.render
        vis.to_svg
      end
      def report_building(builder)
        img_svg=create_svg
        Dir.mktmpdir {|dir|
          time=Time.new.to_f
          File.open("#{dir}/image_#{time}.svg","w") {|fp|
            fp.write img_svg
          }
          builder.image("#{dir}/image_#{time}.svg", :width=>width, :height=>height)
        }
        
      end
    end
  end
end
