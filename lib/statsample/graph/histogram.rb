require 'rubyvis'
module Statsample
  module Graph
    class Histogram
      include Summarizable
      attr_accessor :name
      # Total width of Boxplot
      attr_accessor :width
      # Total height of Boxplot
      attr_accessor :height
      # Top margin
      attr_accessor :margin_top
      # Bottom margin
      attr_accessor :margin_bottom
      # Left margin
      attr_accessor :margin_left
      # Right margin
      attr_accessor :margin_right
      attr_reader :hist
      # Could be an array of ranges or number of bins
      attr_accessor :bins
      # data could be a vector or a histogram
      def initialize(data,opts=Hash.new)
        prov_name=data.respond_to? :name ? data.name : ""
        opts_default={
          :name=>_("Histograma (%s)") % prov_name,
          :width=>400,
          :height=>300,
          :margin_top=>10,
          :margin_bottom=>20,
          :margin_left=>20,
          :margin_right=>20,
          :bins=>nil
        }
        @opts=opts_default.merge(opts)
        opts_default.keys.each {|k| send("#{k}=", @opts[k]) }
        @data=data
      end
      def pre_vis
        if @data.is_a? Statsample::Histogram
          @hist=@data
        elsif @data.is_a? Statsample::Vector
          @bins||=Math::sqrt(@data.size).floor
          @hist=@data.histogram(@bins)
        end
      end
      # Returns a Rubyvis panel with scatterplot
      def rubyvis_panel # :nodoc:
        pre_vis
        that=self
        
        max_bin = @hist.max_val
        
        margin_hor=margin_left + margin_right
        margin_vert=margin_top  + margin_bottom

        x_scale = pv.Scale.linear(@hist.min, @hist.max).range(0,width-margin_hor)

        y_scale=Rubyvis::Scale.linear(0,max_bin).range(0, height-margin_vert)
        
        y_scale.nice
        max_range=@hist.max
        bins=@hist.bins.times.map {|i|
          {
           :low =>@hist.get_range(i)[0],
           :high=>@hist.get_range(i)[1],
           :value=>@hist.bin[i]
          }
        }
        # cache data
        vis=Rubyvis::Panel.new do |pan| 
          pan.width  width  - margin_hor
          pan.height height - margin_vert
          pan.bottom margin_bottom
          pan.left   margin_left
          pan.right  margin_right
          pan.top    margin_top
           # Y axis
          pan.rule do
            data y_scale.ticks
            bottom y_scale
            stroke_style {|d| d!=0 ? "#eee" : "#000"}
            label(:anchor=>'left') do
              text y_scale.tick_format
            end
          end
          # X axis
          pan.rule do
            data(bins+[{:low=>max_range}])
            left {|v| x_scale.scale(v[:low])}
            stroke_style "black"
            height 5
            bottom -5
            label(:anchor=>'bottom') do
              text {|v| x_scale.tick_format.call(v[:low])}
            end
          end
          
          pan.bar do |bar|
            bar.data(bins)
            bar.left {|v| x_scale.scale(v[:low])}
            bar.width {|v| x_scale.scale(v[:high]) - x_scale.scale(v[:low])}
            bar.bottom 0
            bar.height {|v| y_scale.scale(v[:value])}
            bar.stroke_style "black"
            bar.line_width 1
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
