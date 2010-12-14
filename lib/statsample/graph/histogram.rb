require 'rubyvis'
module Statsample
  module Graph
    class Histogram
      include Summarizable
      # Histogram name
      attr_accessor :name
      # Total width
      attr_accessor :width
      # Total height
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
      # Minimum value on x axis. Calculated automaticly from data if not set
      attr_accessor :minimum_x
      # Maximum value on x axis. Calculated automaticly from data if not set
      attr_accessor :maximum_x
      # Minimum value on y axis. Set to 0 if not set
      attr_accessor :minimum_y
      # Maximum value on y axis. Calculated automaticly from data if not set.
      attr_accessor :maximum_y
      # Add a line showing normal distribution
      attr_accessor :line_normal_distribution
      # data could be a vector or a histogram
      def initialize(data,opts=Hash.new)
        prov_name=(data.respond_to?(:name)) ? data.name : ""
        opts_default={
          :name=>_("Histograma (%s)") % prov_name,
          :width=>400,
          :height=>300,
          :margin_top=>10,
          :margin_bottom=>20,
          :margin_left=>30,
          :margin_right=>20,
          :minimum_x=>nil,
          :maximum_x=>nil,
          :minimum_y=>nil,
          :maximum_y=>nil,
          :bins=>nil,
          :line_normal_distribution=>false
        }
        @opts=opts_default.merge(opts)
        opts_default.keys.each {|k| send("#{k}=", @opts[k]) }
        @data=data
      end
      def pre_vis
        if @data.is_a? Statsample::Histogram
          @hist=@data
          @mean=@hist.estimated_mean
          @sd=@hist.estimated_standard_deviation
        elsif @data.is_a? Statsample::Vector
          @mean=@data.mean
          @sd=@data.sd
          @bins||=Math::sqrt(@data.size).floor
          @hist=@data.histogram(@bins)
        end
      end
      def rubyvis_normal_distribution(pan)
        x_scale=@x_scale
        y_scale=@y_scale
        
        wob = @hist.get_range(0)[1] - @hist.get_range(0)[0]
        
        nob = ((@maximum_x-@minimum_x) / wob.to_f).floor
        sum=@hist.sum
        
        data=nob.times.map {|i|
          l=@minimum_x+i*wob
          r=@minimum_x+(i+1)*wob          
          middle=(l+r) / 2.0
          pi=Distribution::Normal.cdf((r-@mean) / @sd) - Distribution::Normal.cdf((l-@mean) / @sd)
          {:x=>middle, :y=>pi*sum}
        }
        pan.line do |l|
          l.data data
          l.interpolate "cardinal"
          l.stroke_style "black"
          l.bottom {|d| y_scale[d[:y]]}
          l.left {|d| x_scale[d[:x]]}
        end
        
      end
      # Returns a Rubyvis panel with scatterplot
      def rubyvis_panel # :nodoc:
        pre_vis
        that=self
        
        @minimum_x||=@hist.min
        @maximum_x||=@hist.max
        @minimum_y||=0
        @maximum_y||=@hist.max_val
        
        margin_hor=margin_left + margin_right
        margin_vert=margin_top  + margin_bottom
      
        x_scale = pv.Scale.linear(@minimum_x, @maximum_x).range(0,width-margin_hor)
      
        y_scale=Rubyvis::Scale.linear(@minimum_y,@maximum_y).range(0, height-margin_vert)
        
        y_scale.nice
        max_range=@hist.max
        bins=@hist.bins.times.map {|i|
          {
           :low =>@hist.get_range(i)[0],
           :high=>@hist.get_range(i)[1],
           :value=>@hist.bin[i]
          }
        }
        @x_scale=x_scale
        @y_scale=y_scale
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
            data x_scale.ticks
            left x_scale
            stroke_style "black"
            height 5
            bottom(-5)
            label(:anchor=>'bottom') do
              text x_scale.tick_format
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
           rubyvis_normal_distribution(pan) if @line_normal_distribution
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
      def report_building_text(generator)
        pre_vis
        #anchor=generator.toc_entry(_("Histogram %s") % [@name])
        step=  @hist.max_val > 40 ? ( @hist.max_val / 40).ceil : 1
          
        @hist.range.each_with_index do |r,i|
          next if i==@hist.bins
          generator.text(sprintf("%5.2f : %s", r, "*" * (@hist.bin[i] / step).floor ))
        end
      end
    end
  end
end
