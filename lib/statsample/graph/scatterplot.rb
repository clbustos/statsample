require 'tmpdir'
require 'rubyvis'
module Statsample
  module Graph
    # = Scatterplot
    # 
    # From Wikipedia:
    # A scatter plot or scattergraph is a type of mathematical diagram using
    # Cartesian coordinates to display values for two variables for a set of data.
    # 
    # The data is displayed as a collection of points, each having the value of one variable determining the position on the horizontal axis and the value of the other variable determining the position on the vertical axis.[2] This kind of plot is also called a scatter chart, scatter diagram and scatter graph.
    # == Usage
    # === Svg output
    #  a=[1,2,3,4].to_scale
    #  b=[3,4,5,6].to_scale
    #  puts Statsample::Graph::Scatterplot.new(a,b).to_svg
    # === Using ReportBuilder
    #  a=[1,2,3,4].to_scale
    #  b=[3,4,5,6].to_scale
    #  rb=ReportBuilder.new
    #  rb.add(Statsample::Graph::Scatterplot.new(a,b))
    #  rb.save_html('scatter.html')
    
    class Scatterplot
      include Summarizable
      attr_accessor :name
      # Total width of Scatterplot
      attr_accessor :width
      # Total height of Scatterplot
      attr_accessor :height
      attr_accessor :dot_alpha
      # Add a line on median of x and y axis 
      attr_accessor :line_median
      # Top margin
      attr_accessor :margin_top
      # Bottom margin
      attr_accessor :margin_bottom
      # Left margin
      attr_accessor :margin_left
      # Right margin
      attr_accessor :margin_right
      
      attr_reader   :data
      attr_reader :v1,:v2
      attr_reader :x_scale, :y_scale
      # Create a new Scatterplot.
      # Params:
      # * v1: Vector on X axis
      # * v2: Vector on Y axis
      # * opts: Hash of options. See attributes of Scatterplot
      def initialize(v1,v2,opts=Hash.new)
        @v1_name,@v2_name = v1.name,v2.name
        @v1,@v2           = Statsample.only_valid_clone(v1,v2)
        opts_default={
          :name=>_("Scatterplot (%s - %s)") % [@v1_name, @v2_name],
          :width=>400,
          :height=>300,
          :dot_alpha=>0.5,
          :line_median=>false,
          :margin_top=>10,
          :margin_bottom=>20,
          :margin_left=>20,
          :margin_right=>20
          
        }
        @opts=opts_default.merge(opts)
        opts_default.keys.each {|k| send("#{k}=", @opts[k]) }
        @data=[]
        @v1.each_with_index {|d1,i|
          @data.push({:x=>d1,:y=>@v2[i]})
        }
      end
      # Add a rule on median of X and Y axis
      def add_line_median(vis) # :nodoc:
        that=self
        x=@x_scale
        y=@y_scale
        vis.execute {
          rule do
            data [that.v1.median]
            left x
            stroke_style Rubyvis.color("#933").alpha(0.5)
            label(:anchor=>"top") do
              text x.tick_format
            end
          end
          rule do
            data [that.v2.median]
            bottom y
            stroke_style Rubyvis.color("#933").alpha(0.5)
            label(:anchor=>"right") do
              text y.tick_format
            end
          end  
        }
        
      end
      # Returns a Rubyvis panel with scatterplot
      def rubyvis_panel # :nodoc:
        that=self
        #p @v1.map {|v| v}
        x=Rubyvis::Scale.linear(@v1.to_a).range(0,width)
        y=Rubyvis::Scale.linear(@v2.to_a).range(0,height)
        @x_scale=x
        @y_scale=y
        vis=Rubyvis::Panel.new do |pan| 
          pan.width  width  - (margin_left + margin_right)
          pan.height height - (margin_top  + margin_bottom)
          pan.bottom margin_bottom
          pan.left   margin_left
          pan.right  margin_right
          pan.top    margin_top
          # X axis
          pan.rule do
            data y.ticks
            bottom y
            stroke_style {|d| d!=0 ? "#eee" : "#000"}
            label(:anchor=>'left') do
              visible {|d| d>0 and d<that.width}
              text y.tick_format
            end
          end
          
          # Y axis
          pan.rule do
            data x.ticks
            left x
            stroke_style {|d| d!=0 ? "#eee" : "#000"}
            label(:anchor=>'bottom') do
              visible {|d| d>0 and d < that.height}
              text x.tick_format
            end
          end
          # Add lines on median
          add_line_median(pan) if line_median

          pan.panel do
            data(that.data)
            dot do
              left {|d| x.scale(d[:x])}
              bottom {|d| y.scale(d[:y])}
              stroke_style Rubyvis.color("red").alpha(that.dot_alpha)
              shape_radius 2
            end
          end
        end
      end
      # Returns SVG with scatterplot
      def to_svg
        rp=rubyvis_panel
        rp.render
        rp.to_svg
      end
      def report_building(builder) # :nodoc:
        builder.section(:name=>name) do |b|
          b.image(to_svg, :type=>'svg', :width=>width, :height=>height)
        end
        
      end
    end
  end
end
