module Statsample
  module Graph
    class SvgScatterplot < SVG::Graph::Plot # :nodoc:
      attr_accessor :draw_path
      def initialize(ds,config={})
          super(config)
          @ds=ds
          set_x(@ds.fields[0])
      end
      def set_defaults
          super
          init_with(
              :show_data_values => false,
              :draw_path => false
              )
      end
      def set_x(x)
          @x=x
          @y=@ds.fields - [x]
      end
      def parse
        data=@y.inject({}){|a,v| a[v]=[];a}
        @ds.each{|row|
          @y.each{|y|
              data[y]+=[row[@x],row[y]] unless row[@x].nil? or row[y].nil?
          }
        }
        data.each{|y,d|
          add_data({
                  :data=>d, :title=>@ds.vector_label(y)
          })
        }
      end
      def get_x_labels
        values=super
        values.collect{|x|
          if x.is_a? Integer
              x 
          else
              sprintf("%0.2f",x).to_f
          end
        }
      end
      def get_y_labels
        values=super
        values.collect{|x|
          if x.is_a? Integer
              x 
          else
              sprintf("%0.2f",x).to_f
          end
        }
      end
      def draw_data
        line = 1
        
        x_min, x_max, x_div = x_range
        y_min, y_max, y_div = y_range
        x_step = (@graph_width.to_f - font_size*2) / (x_max-x_min)
        y_step = (@graph_height.to_f -  font_size*2) / (y_max-y_min)
        
        for data in @data
        x_points = data[:data][X]
        y_points = data[:data][Y]
        
        lpath = "L"
        x_start = 0
        y_start = 0
        x_points.each_index { |idx|
        x = (x_points[idx] -  x_min) * x_step
        y = @graph_height - (y_points[idx] -  y_min) * y_step
        x_start, y_start = x,y if idx == 0
        lpath << "#{x} #{y} "
        }
        
        if area_fill
        @graph.add_element( "path", {
          "d" => "M#{x_start} #@graph_height #{lpath} V#@graph_height Z",
          "class" => "fill#{line}"
        })
        end
        if draw_path
        @graph.add_element( "path", {
        "d" => "M#{x_start} #{y_start} #{lpath}",
        "class" => "line#{line}"
        })
        end
        if show_data_points || show_data_values
        x_points.each_index { |idx|
          x = (x_points[idx] -  x_min) * x_step
          y = @graph_height - (y_points[idx] -  y_min) * y_step
          if show_data_points
            @graph.add_element( "circle", {
              "cx" => x.to_s,
              "cy" => y.to_s,
              "r" => "2.5",
              "class" => "dataPoint#{line}"
            })
            add_popup(x, y, format( x_points[idx], y_points[idx] )) if add_popups
          end
          make_datapoint_text( x, y-6, y_points[idx] ) if show_data_values
        }
        end
        line += 1
        end
      end
    end
  end
end
