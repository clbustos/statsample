require 'rubyvis'
module Statsample
  module Graph
    # = Boxplot
    # 
    # From Wikipedia:
    # In descriptive statistics, a box plot or boxplot (also known as a box-and-whisker diagram or plot) is a convenient way of graphically depicting groups of numerical data through their five-number summaries: the smallest observation (sample minimum), lower quartile (Q1), median (Q2), upper quartile (Q3), and largest observation (sample maximum). A boxplot may also indicate which observations, if any, might be considered outliers.
    # 
    # == Usage
    # === Svg output
    #  a = Daru::Vector.new([1,2,3,4])
    #  b = Daru::Vector.new([3,4,5,6])
    # puts Statsample::Graph::Boxplot.new(:vectors=>[a,b]).to_svg
    # === Using ReportBuilder
    #  a = Daru::Vector.new([1,2,3,4])
    #  b = Daru::Vector.new([3,4,5,6])
    #  rb=ReportBuilder.new
    #  rb.add(Statsample::Graph::Boxplot.new(:vectors=>[a,b]))
    #  rb.save_html('boxplot.html')
    
    class Boxplot
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
      # Array with assignation to groups of bars
      # For example, for four vectors, 
      #   boxplot.groups=[1,2,1,3]
      # Assign same color to first and third element, and different to
      # second and fourth
      attr_accessor :groups
      # Minimum value on y-axis. Automaticly defined from data
      attr_accessor :minimum
      # Maximum value on y-axis. Automaticly defined from data
      attr_accessor :maximum
      # Vectors to box-ploting
      attr_accessor :vectors
      # The rotation angle, in radians. Text is rotated clockwise relative 
      # to the anchor location. For example, with the default left alignment, 
      # an angle of Math.PI / 2 causes text to proceed downwards. The default angle is zero.      
      attr_accessor :label_angle
      attr_reader :x_scale, :y_scale
      # Create a new Boxplot.
      # Parameters: Hash of options
      # * :vectors: Array of vectors
      # * :groups: Array of same size as :vectors:, with name of groups
      #           to colorize vectors
      def initialize(opts=Hash.new)
        @vectors=opts.delete :vectors
        raise "You should define vectors" if @vectors.nil?
        
        opts_default={
          :name=>_("Boxplot"),
          :groups=>nil,
          :width=>400,
          :height=>300,
          :margin_top=>10,
          :margin_bottom=>20,
          :margin_left=>20,
          :margin_right=>20,
          :minimum=>nil,
          :maximum=>nil,
          :label_angle=>0
        }
        @opts=opts_default.merge(opts)
        opts_default.keys.each {|k| send("#{k}=", @opts[k]) }
      end
      
      # Returns a Rubyvis panel with scatterplot
      def rubyvis_panel # :nodoc:
        that=self
        
        min,max=@minimum, @maximum
        
        min||=@vectors.map {|v| v.min}.min
        max||=@vectors.map {|v| v.max}.max
        
        margin_hor=margin_left + margin_right
        margin_vert=margin_top  + margin_bottom
        x_scale = pv.Scale.ordinal(@vectors.size.times.map.to_a).split_banded(0, width-margin_hor, 4.0/5)
        y_scale=Rubyvis::Scale.linear(min,max).range(0,height-margin_vert)
        y_scale.nice
        # cache data
        
        colors=Rubyvis::Colors.category10
        
        data=@vectors.map {|v|
          out={:percentil_25=>v.percentil(25), :median=>v.median, :percentil_75=>v.percentil(75), :name=>v.name}
          out[:iqr]=out[:percentil_75] - out[:percentil_25]
          
          irq_max=out[:percentil_75] + out[:iqr]
          irq_min=out[:percentil_25] - out[:iqr]
          
          # Find the last data inside the margin
          min = out[:percentil_25]
          max = out[:percentil_75]
          
          v.each {|d|
            min=d if d < min and d > irq_min
            max=d if d > max and d < irq_max
          }
          # Whiskers!
          out[:low_whisker]=min
          out[:high_whisker]=max
          # And now, data outside whiskers
          out[:outliers]=v.to_a.find_all {|d| d < min or d > max }
          out
        }
               
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
          pan.rule do
            bottom 0
            stroke_style 'black'
          end
          
          # Labels
          
          pan.label  do |l|
            l.data data
            l.text_angle that.label_angle
            l.left  {|v| x_scale[index] }
            l.bottom(-15)
            l.text {|v,x| v[:name]}
          end
          
          pan.panel do |bp|
            bp.data data
            bp.left {|v|  x_scale[index]}
            bp.width x_scale.range_band
            
            # Bar
            bp.bar do |b|
              b.bottom {|v| y_scale[v[:percentil_25]]}
              b.height {|v| y_scale[v[:percentil_75]] - y_scale[v[:percentil_25]] }
              b.line_width 1
              b.stroke_style  {|v| 
                if that.groups
                  colors.scale(that.groups[parent.index]).darker
                else
                  colors.scale(index).darker
                end  
              }
              b.fill_style {|v| 
                if that.groups
                  colors.scale(that.groups[parent.index])
                else
                  colors.scale(index)
                end
              }
            end
            # Median
            bp.rule do |r|
              r.bottom {|v| y_scale[v[:median]]}
              r.width x_scale.range_band
              r.line_width 2
            end
            ##
            # Whiskeys
            ##
            # Low whiskey
            bp.rule do |r|
              r.visible {|v| v[:percentil_25] > v[:low_whisker]}
              r.bottom {|v| y_scale[v[:low_whisker]]}              
            end
            
            bp.rule do |r|
              r.visible {|v| v[:percentil_25] > v[:low_whisker]}
              r.bottom {|v| y_scale[v[:low_whisker]]}              
              r.left {|v| x_scale.range_band / 2.0}
              r.height {|v| y_scale.scale(v[:percentil_25]) - y_scale.scale(v[:low_whisker])}
            end
            # High whiskey

            bp.rule do |r|
              r.visible {|v| v[:percentil_75] < v[:high_whisker]}
              r.bottom {|v| y_scale.scale(v[:high_whisker])}              
            end
            
             bp.rule do |r|
              r.visible {|v| v[:percentil_75] < v[:high_whisker]}
              r.bottom {|v| y_scale.scale(v[:percentil_75])}              
              r.left {|v| x_scale.range_band / 2.0}
              r.height {|v| y_scale.scale(v[:high_whisker]) - y_scale.scale(v[:percentil_75])}
            end
            # Outliers
            bp.dot do |dot|
              dot.shape_size 4
              dot.data {|v| v[:outliers]}
              dot.left {|v| x_scale.range_band / 2.0}
              dot.bottom {|v| y_scale.scale(v)}
              dot.title {|v| v}
            end
          end
        end
        vis
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
