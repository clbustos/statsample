require 'SVG/Graph/Bar'
require 'SVG/Graph/BarHorizontal'
require 'SVG/Graph/Pie'
require 'SVG/Graph/Line'
require 'SVG/Graph/Plot'
require 'statsample/graph/svghistogram'

module Statsample
  class Vector
    # Creates a barchart using ruby-gdchart
    def svggraph_frequencies(file, width=600, height=300, chart_type=SVG::Graph::BarNoOp, options={})
      labels, data1=[],[]
      self.frequencies.sort.each{|k,v|
        labels.push(k.to_s)
        data1.push(v)
      }
      options[:height]=height
      options[:width]=width
      options[:fields]=labels
      graph = chart_type.new(options)
      graph.add_data(
      :data => data1,
      :title => "Frequencies"
      )

      File.open(file,"w") {|f|
        f.puts(graph.burn)
      }
    end
    def svggraph_histogram(bins, options={})
      check_type :scale
      options={:graph_title=>"Histogram", :show_graph_title=>true,:show_normal=>true, :mean=>self.mean, :sigma=>sdp }.merge! options
      graph = Statsample::Graph::SvgHistogram.new(options)
      graph.histogram=histogram(bins)
      graph
    end
    # Returns a Run-Sequence Plot
    # Reference: http://www.itl.nist.gov/div898/handbook/eda/section3/runseqpl.htm
    def svggraph_runsequence_plot(options={})
      check_type :scale
      options={:graph_title=>"Run-Sequence Plot", :show_graph_title=>true, :scale_x_integers => true, :add_popups=>true }.merge! options
      vx=(1..@data.size).to_a.to_vector(:scale)
      vy=@data.to_vector(:scale)
      ds={'index'=>vx,'value'=>vy}.to_dataset
      graph = Statsample::Graph::SvgScatterplot.new(ds,options)
      graph.set_x('index')
      graph.parse
      graph
    end
    def svggraph_boxplot(options={})
      check_type :scale
      options={:graph_title=>"Boxplot", :fields=>['vector'], :show_graph_title=>true}.merge! options
      vx=@valid_data.to_a.to_vector(:scale)
      graph = Statsample::Graph::SvgBoxplot.new(options)
      graph.add_data(:title=>"vector", :data=>@data.to_a)
      graph
    end

    def svggraph_lag_plot(options={})
      check_type :scale
      options={:graph_title=>"Lag Plot", :show_graph_title=>true}.merge! options
      vx=@valid_data[0...(@valid_data.size-1)].to_vector(:scale)
      vy=@valid_data[1...@valid_data.size].to_vector(:scale)
      ds={'x_minus_1'=>vx,'x'=>vy}.to_dataset
      graph = Statsample::Graph::SvgScatterplot.new(ds,options)
      graph.set_x('x_minus_1')
      graph.parse
      graph
    end
    # Returns a Normal Probability Plot
    # Reference: http://www.itl.nist.gov/div898/handbook/eda/section3/normprpl.htm
    def svggraph_normalprobability_plot(options={})
      extend Statsample::Util
      check_type :scale
      options={:graph_title=>"Normal Probability Plot", :show_graph_title=>true}.merge! options
      n=@valid_data.size
      vx=(1..@valid_data.size).to_a.collect{|i|
        Distribution::Normal.p_value(normal_order_statistic_medians(i,n))
      }.to_vector(:scale)
      vy=@valid_data.sort.to_vector(:scale)
      ds={'normal_order_statistics_medians'=>vx, 'ordered_response'=>vy}.to_dataset
      graph = Statsample::Graph::SvgScatterplot.new(ds,options)
      graph.set_x('normal_order_statistics_medians')
      graph.parse
      graph
    end
  end
end

# replaces all key and fill classes with similar ones, without opacity
# this allows rendering of svg and png on rox and gqview without problems
module SVG #:nodoc:
  module Graph
    class BarNoOp < Bar # :nodoc:
      def get_css; SVG::Graph.get_css_standard; end
    end
    class BarHorizontalNoOp < BarHorizontal
      def get_css; SVG::Graph.get_css_standard; end
    end

    class LineNoOp < Line
      def get_css; SVG::Graph.get_css_standard; end

    end
    class PlotNoOp < Plot
      def get_css; SVG::Graph.get_css_standard; end
    end
    class PieNoOp < Pie
      def get_css; SVG::Graph.get_css_standard; end

    end
    class << self
      def get_css_standard
        return <<-EOL
        /* default fill styles for multiple datasets (probably only use a single dataset on this graph though) */
        .key1,.fill1{
          fill: #ff0000;
          stroke: none;
          stroke-width: 0.5px;
        }
        .key2,.fill2{
          fill: #0000ff;
          stroke: none;
          stroke-width: 1px;
        }
        .key3,.fill3{
          fill: #00ff00;
          stroke: none;
          stroke-width: 1px;
        }
        .key4,.fill4{
          fill: #ffcc00;
          stroke: none;
          stroke-width: 1px;
        }
        .key5,.fill5{
          fill: #00ccff;
          stroke: none;
          stroke-width: 1px;
        }
        .key6,.fill6{
          fill: #ff00ff;
          stroke: none;
          stroke-width: 1px;
        }
        .key7,.fill7{
          fill: #00ffff;
          stroke: none;
          stroke-width: 1px;
        }
        .key8,.fill8{
          fill: #ffff00;
          stroke: none;
          stroke-width: 1px;
        }
        .key9,.fill9{
          fill: #cc6666;
          stroke: none;
          stroke-width: 1px;
        }
        .key10,.fill10{
          fill: #663399;
          stroke: none;
          stroke-width: 1px;
        }
        .key11,.fill11{
          fill: #339900;
          stroke: none;
          stroke-width: 1px;
        }
        .key12,.fill12{
          fill: #9966FF;
          stroke: none;
          stroke-width: 1px;
        }
        EOL
      end
    end
  end
end

require 'statsample/graph/svgscatterplot'
require 'statsample/graph/svgboxplot'
