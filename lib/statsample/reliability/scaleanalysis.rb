module Statsample
  module Reliability
    # Analysis of a Scale. Analoge of Scale Reliability analysis on SPSS.
    # Returns several statistics for complete scale and each item
    # == Usage
    #  @x1=[1,1,1,1,2,2,2,2,3,3,3,30].to_vector(:scale)
    #  @x2=[1,1,1,2,2,3,3,3,3,4,4,50].to_vector(:scale)
    #  @x3=[2,2,1,1,1,2,2,2,3,4,5,40].to_vector(:scale)
    #  @x4=[1,2,3,4,4,4,4,3,4,4,5,30].to_vector(:scale)
    #  ds={'x1'=>@x1,'x2'=>@x2,'x3'=>@x3,'x4'=>@x4}.to_dataset
    #  ia=Statsample::Reliability::ScaleAnalysis.new(ds)
    #  puts ia.summary
    class ScaleAnalysis
      include Summarizable
      attr_reader :ds,:mean, :sd,:valid_n, :alpha , :alpha_standarized, :variances_mean, :covariances_mean
      attr_accessor :name
      def initialize(ds, opts=Hash.new)
        @ds=ds.dup_only_valid
        @k=@ds.fields.size
        @total=@ds.vector_sum
        @item_mean=@ds.vector_mean.mean
        @mean=@total.mean
        @median=@total.median
        @skew=@total.skew
        @kurtosis=@total.kurtosis
        @sd = @total.sd
        @variance=@total.variance
        @valid_n = @total.size
        opts_default={:name=>"Reliability Analisis"}
        @opts=opts_default.merge(opts)
        @name=@opts[:name]
        # Mean for covariances and variances
        @variances=@ds.fields.map {|f| @ds[f].variance}.to_scale
        @variances_mean=@variances.mean
        @covariances_mean=(@variance-@variances.sum).quo(@k**2-@k)
        begin
          @alpha = Statsample::Reliability.cronbach_alpha(ds)
          @alpha_standarized = Statsample::Reliability.cronbach_alpha_standarized(ds)
        rescue => e
          raise DatasetException.new(@ds,e), "Error calculating alpha"
        end
      end
      # Returns a hash with structure
      def item_characteristic_curve
        i=0
        out={}
        total={}
        @ds.each do |row|
          tot=@total[i]
          @ds.fields.each do |f|
            out[f]||= {}
            total[f]||={}
            out[f][tot]||= 0
            total[f][tot]||=0
            out[f][tot]+= row[f]
            total[f][tot]+=1
          end
          i+=1
        end
        total.each do |f,var|
          var.each do |tot,v|
            out[f][tot]=out[f][tot].to_f / total[f][tot]
          end
        end
        out
      end
      def gnuplot_item_characteristic_curve(directory, base="crd",options={})
        require 'gnuplot'

        crd=item_characteristic_curve
        @ds.fields.each  do |f|
          x=[]
          y=[]
          Gnuplot.open do |gp|
            Gnuplot::Plot.new( gp ) do |plot|
              crd[f].sort.each do |tot,prop|
                x.push(tot)
                y.push((prop*100).to_i.to_f/100)
              end
              plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
                ds.with = "linespoints"
                ds.notitle
              end

            end
          end
        end
      end
      def svggraph_item_characteristic_curve(directory, base="icc",options={})
        require 'statsample/graph/svggraph'
        crd=ItemCharacteristicCurve.new(@ds)
        @ds.fields.each do |f|
          factors=@ds[f].factors.sort
          options={
            :height=>500,
            :width=>800,
            :key=>true
          }.update(options)
          graph = ::SVG::Graph::Plot.new(options)
          factors.each do |factor|
            factor=factor.to_s
            dataset=[]
            crd.curve_field(f, factor).each do |tot,prop|
              dataset.push(tot)
              dataset.push((prop*100).to_i.to_f/100)
            end
            graph.add_data({
              :title=>"#{factor}",
              :data=>dataset
            })
          end
          File.open(directory+"/"+base+"_#{f}.svg","w") {|fp|
            fp.puts(graph.burn())
          }
        end
      end
      def item_total_correlation
        @ds.fields.inject({}) do |a,v|
          vector=@ds[v].clone
          ds2=@ds.clone
          ds2.delete_vector(v)
          total=ds2.vector_sum
          a[v]=Statsample::Bivariate.pearson(vector,total)
          a
        end
      end
      def item_statistics
        @ds.fields.inject({}) do |a,v|
          a[v]={:mean=>@ds[v].mean,:sds=>@ds[v].sds}
          a
        end
      end
      # Returns a dataset with cases ordered by score
      # and variables ordered by difficulty

      def item_difficulty_analysis
        dif={}
        @ds.fields.each{|f| dif[f]=@ds[f].mean }
        dif_sort=dif.sort{|a,b| -(a[1]<=>b[1])}
        scores_sort={}
        scores=@ds.vector_mean
        scores.each_index{|i| scores_sort[i]=scores[i] }
        scores_sort=scores_sort.sort{|a,b| a[1]<=>b[1]}
        ds_new=Statsample::Dataset.new(['case','score'] + dif_sort.collect{|a,b| a})
        scores_sort.each do |i,score|
          row=[i, score]
          case_row=@ds.case_as_hash(i)
          dif_sort.each{|variable,dif_value| row.push(case_row[variable]) }
          ds_new.add_case_array(row)
        end
        ds_new.update_valid_data
        ds_new
      end
      def stats_if_deleted
        @ds.fields.inject({}) do |a,v|
          ds2=@ds.clone
          ds2.delete_vector(v)
          total=ds2.vector_sum
          a[v]={}
          a[v][:mean]=total.mean
          a[v][:sds]=total.sds
          a[v][:variance_sample]=total.variance_sample
          a[v][:alpha]=Statsample::Reliability.cronbach_alpha(ds2)
          a
        end
      end
      def report_building(builder) #:nodoc:
        builder.section(:name=>@name) do |s|
          s.table(:name=>_("Summary for %s") % @name) do |t|
          t.row [_("Items"), @ds.fields.size]
          t.row [_("Valid cases"), @valid_n]
          t.row [_("Sum mean"), @mean]
          t.row [_("Sum sd"), @sd]
          t.row [_("Sum variance"), @variance]
          t.row [_("Sum median"), @median]
          t.hr
          t.row [_("Item mean"), @item_mean]
          t.row [_("Skewness"), "%0.4f" % @skew]
          t.row [_("Kurtosis"), "%0.4f" % @kurtosis]
          t.hr
          t.row [_("Cronbach's alpha"), "%0.4f" % @alpha]
          t.row [_("Standarized Cronbach's alpha"), "%0.4f" % @alpha_standarized]
          t.row [_("Variances mean"),  "%g" % @variances_mean]
          t.row [_("Covariances mean") , "%g" % @covariances_mean]
          end
          s.text _("items for obtain alpha(0.8) : %d" % Statsample::Reliability::n_for_desired_alpha(0.8, @variances_mean,@covariances_mean))
          s.text _("items for obtain alpha(0.9) : %d" % Statsample::Reliability::n_for_desired_alpha(0.9, @variances_mean,@covariances_mean))          
          itc=item_total_correlation
          sid=stats_if_deleted
          is=item_statistics
          
          
          
          s.table(:name=>_("Items report for %s") % @name, :header=>["item","mean","sd", "mean if deleted", "var if deleted", "sd if deleted"," item-total correl.", "alpha if deleted"]) do |t|
            @ds.fields.each do |f|
              t.row(["#{@ds[f].name}(#{f})", sprintf("%0.5f",is[f][:mean]), sprintf("%0.5f",is[f][:sds]), sprintf("%0.5f",sid[f][:mean]), sprintf("%0.5f",sid[f][:variance_sample]), sprintf("%0.5f",sid[f][:sds]),  sprintf("%0.5f",itc[f]), sprintf("%0.5f",sid[f][:alpha])])
            end # end each
          end # table
        end # section
      end # def
    end # class
  end # module
end # module
