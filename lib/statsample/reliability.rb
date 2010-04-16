module Statsample
  module Reliability
    class << self
      # Calculate Chonbach's alpha for a given dataset.
      # only uses tuples without missing data
      def cronbach_alpha(ods)
        ds=ods.dup_only_valid
        n_items=ds.fields.size
        sum_var_items=ds.vectors.inject(0) {|ac,v|
        ac+v[1].variance }
        total=ds.vector_sum
        (n_items.quo(n_items-1)) * (1-(sum_var_items.quo(total.variance)))
      end
      # Calculate Chonbach's alpha for a given dataset
      # using standarized values for every vector.
      # Only uses tuples without missing data

      def cronbach_alpha_standarized(ods)
        ds=ods.dup_only_valid.fields.inject({}){|a,f|
          a[f]=ods[f].standarized; a
        }.to_dataset
        cronbach_alpha(ds)
      end
    end
    class ItemCharacteristicCurve
      attr_reader :totals, :counts, :vector_total
      def initialize (ds, vector_total=nil)
        vector_total||=ds.vector_sum
        raise ArgumentError, "Total size != Dataset size" if vector_total.size!=ds.cases
        @vector_total=vector_total
        @ds=ds
        @totals={}
        @counts=@ds.fields.inject({}) {|a,v| a[v]={};a}
        process
      end
      def process
        i=0
        @ds.each do |row|
          tot=@vector_total[i]
          @totals[tot]||=0
          @totals[tot]+=1
          @ds.fields.each  do |f|
            item=row[f].to_s
            @counts[f][tot]||={}
            @counts[f][tot][item]||=0
            @counts[f][tot][item] += 1
          end
          i+=1
        end
      end
      # Return a hash with p for each different value on a vector
      def curve_field(field, item)
        out={}
        item=item.to_s
        @totals.each do |value,n|
          count_value= @counts[field][value][item].nil? ? 0 : @counts[field][value][item]
          out[value]=count_value.quo(n)
        end
        out
      end
    end
    class ItemAnalysis
      attr_reader :mean, :sd,:valid_n, :alpha , :alpha_standarized
      attr_accessor :name
      def initialize(ds,opts=Hash.new)
        @ds=ds.dup_only_valid
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
          vector=@ds[v].dup
          ds2=@ds.dup
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
          ds2=@ds.dup
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
      def summary
        ReportBuilder.new(:no_title=>true).add(self).to_text
      end
      def report_building(builder)
        builder.section(:name=>@name) do |s|
          s.table(:name=>"Summary") do |t|
            t.row ["Items", @ds.fields.size]
            t.row ["Total Mean", @mean]
            t.row ["Total S.D.", @sd]
			t.row ["Total Variance", @variance]
			t.row ["Item Mean", @item_mean]
            t.row ["Median", @median]
            t.row ["Skewness", "%0.4f" % @skew]
            t.row ["Kurtosis", "%0.4f" % @kurtosis]
            t.row ["Valid n", @valid_n]
            t.row ["Cronbach's alpha", "%0.4f" % @alpha]
            t.row ["Standarized Cronbach's alpha", "%0.4f" % @alpha_standarized]
          end
          itc=item_total_correlation
          sid=stats_if_deleted
          is=item_statistics

          s.table(:name=>"Items report", :header=>["item","mean","sd", "mean if deleted", "var if deleted", "sd if deleted"," item-total correl.", "alpha if deleted"]) do |t|
            @ds.fields.each do |f|
              t.row(["#{@ds[f].name}(#{f})", sprintf("%0.5f",is[f][:mean]), sprintf("%0.5f",is[f][:sds]), sprintf("%0.5f",sid[f][:mean]), sprintf("%0.5f",sid[f][:variance_sample]), sprintf("%0.5f",sid[f][:sds]),  sprintf("%0.5f",itc[f]), sprintf("%0.5f",sid[f][:alpha])])
            end
          end
          end
      end
    end
  end
end
