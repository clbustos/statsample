module Statsample
  module Reliability
    # Analysis of a Scale. Analoge of Scale Reliability analysis on SPSS.
    # Returns several statistics for complete scale and each item
    # == Usage
    #  @x1 = Daru::Vector.new([1,1,1,1,2,2,2,2,3,3,3,30])
    #  @x2 = Daru::Vector.new([1,1,1,2,2,3,3,3,3,4,4,50])
    #  @x3 = Daru::Vector.new([2,2,1,1,1,2,2,2,3,4,5,40])
    #  @x4 = Daru::Vector.new([1,2,3,4,4,4,4,3,4,4,5,30])
    #  ds  = Daru::DataFrame.new({:x1 => @x1,:x2 => @x2,:x3 => @x3,:x4 => @x4})
    #  ia  = Statsample::Reliability::ScaleAnalysis.new(ds)
    #  puts ia.summary
    class ScaleAnalysis
      include Summarizable
      attr_reader :ds,:mean, :sd,:valid_n, :alpha , :alpha_standarized, :variances_mean, :covariances_mean, :cov_m
      attr_accessor :name
      attr_accessor :summary_histogram
      def initialize(ds, opts=Hash.new)
        @dumped=ds.vectors.to_a.find_all {|f|
          ds[f].variance == 0
        }
        
        @ods = ds
        @ds  = ds.dup_only_valid(ds.vectors.to_a - @dumped)
        @ds.rename ds.name
        
        @k     = @ds.ncols
        @total = @ds.vector_sum
        @o_total=@dumped.size > 0 ? @ods.vector_sum : nil
        
        @vector_mean = @ds.vector_mean
        @item_mean   = @vector_mean.mean
        @item_sd     = @vector_mean.sd
        
        @mean     = @total.mean
        @median   = @total.median
        @skew     = @total.skew
        @kurtosis = @total.kurtosis
        @sd       = @total.sd
        @variance = @total.variance
        @valid_n  = @total.size

        opts_default = {
          :name => _("Reliability Analysis"),
          :summary_histogram => true
        }
        @opts = opts_default.merge(opts)
        @opts.each{ |k,v| self.send("#{k}=",v) if self.respond_to? k }
        
        @cov_m=Statsample::Bivariate.covariance_matrix(@ds)
        # Mean for covariances and variances
        @variances = Daru::Vector.new(@k.times.map { |i| @cov_m[i,i] })
        @variances_mean=@variances.mean
        @covariances_mean=(@variance-@variances.sum).quo(@k**2-@k)
        #begin
          @alpha = Statsample::Reliability.cronbach_alpha(@ds)
          @alpha_standarized = Statsample::Reliability.cronbach_alpha_standarized(@ds)
        #rescue => e
        #  raise DatasetException.new(@ds,e), "Error calculating alpha"
        #end
      end
      # Returns a hash with structure
      def item_characteristic_curve
        i=0
        out={}
        total={}
        @ds.each do |row|
          tot=@total[i]
          @ds.vectors.each do |f|
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
            out[f][tot]=out[f][tot].quo(total[f][tot])
          end
        end
        out
      end
      # =Adjusted R.P.B. for each item
      # Adjusted RPB(Point biserial-correlation) for each item
      #
      def item_total_correlation
        vecs = @ds.vectors.to_a
        @itc ||= vecs.inject({}) do |a,v|
          total=@ds.vector_sum(vecs - [v])
          a[v]=Statsample::Bivariate.pearson(@ds[v],total)
          a
        end
      end
      def mean_rpb
        Daru::Vector.new(item_total_correlation.values).mean
      end
      def item_statistics
        @is||=@ds.vectors.to_a.inject({}) do |a,v|
          a[v]={:mean=>@ds[v].mean, :sds=>Math::sqrt(@cov_m.variance(v))}
          a
        end
      end
      # Returns a dataset with cases ordered by score
      # and variables ordered by difficulty

      def item_difficulty_analysis
        dif={}
        @ds.vectors.each{|f| dif[f]=@ds[f].mean }
        dif_sort = dif.sort { |a,b| -(a[1]<=>b[1]) }
        scores_sort={}
        scores=@ds.vector_mean
        scores.each_index{ |i| scores_sort[i]=scores[i] }
        scores_sort=scores_sort.sort{|a,b| a[1]<=>b[1]}
        ds_new = Daru::DataFrame.new({}, order: ([:case,:score] + dif_sort.collect{|a,b| a.to_sym}))
        scores_sort.each do |i,score|
          row = [i, score]
          case_row = @ds.row[i].to_hash
          dif_sort.each{ |variable,dif_value| row.push(case_row[variable]) }
          ds_new.add_row(row)
        end
        ds_new.update
        ds_new
      end
      
      def stats_if_deleted
        @sif||=stats_if_deleted_intern
      end
      
      def stats_if_deleted_intern # :nodoc:
        return Hash.new if @ds.ncols == 1
        vecs = @ds.vectors.to_a
        vecs.inject({}) do |a,v|
          cov_2=@cov_m.submatrix(vecs - [v])
          #ds2=@ds.clone
          #ds2.delete_vector(v)
          #total=ds2.vector_sum
          a[v]={}
          #a[v][:mean]=total.mean
          a[v][:mean]=@mean-item_statistics[v][:mean]
          a[v][:variance_sample]=cov_2.total_sum
          a[v][:sds]=Math::sqrt(a[v][:variance_sample])
          n=cov_2.row_size
          a[v][:alpha] = (n>=2) ? Statsample::Reliability.cronbach_alpha_from_covariance_matrix(cov_2) : nil
          a
        end
      end
      def report_building(builder) #:nodoc:
        builder.section(:name=>@name) do |s|
          
          if @dumped.size>0
            s.section(:name=>"Items with variance=0") do |s1|
              s.table(:name=>_("Summary for %s with all items") % @name) do |t|
                t.row [_("Items"), @ods.ncols]
                t.row [_("Sum mean"),     "%0.4f" % @o_total.mean]
                t.row [_("S.d. mean"),     "%0.4f" % @o_total.sd]
              end
              s.table(:name=>_("Deleted items"), :header=>['item','mean']) do |t|
                @dumped.each do |f|
                  t.row(["#{@ods[f].name}(#{f})", "%0.5f" % @ods[f].mean])
                end
              end
              s.parse_element(Statsample::Graph::Histogram.new(@o_total, :name=>"Histogram (complete data) for %s" % @name)) if @summary_histogram
            end
          end
          
          
          s.table(:name=>_("Summary for %s") % @name) do |t|
            t.row [_("Valid Items"), @ds.ncols]
          
          t.row [_("Valid cases"), @valid_n]
          t.row [_("Sum mean"),     "%0.4f" % @mean]
          t.row [_("Sum sd"),       "%0.4f" % @sd  ]
#          t.row [_("Sum variance"), "%0.4f" % @variance]
          t.row [_("Sum median"),   @median]
          t.hr
          t.row [_("Item mean"),    "%0.4f" % @item_mean]
          t.row [_("Item sd"),    "%0.4f" % @item_sd]
          t.hr
          t.row [_("Skewness"),     "%0.4f" % @skew]
          t.row [_("Kurtosis"),     "%0.4f" % @kurtosis]
          t.hr
          t.row [_("Cronbach's alpha"), @alpha ? ("%0.4f" % @alpha) : "--"]
          t.row [_("Standarized Cronbach's alpha"), @alpha_standarized ? ("%0.4f" % @alpha_standarized) : "--" ]
          t.row [_("Mean rpb"), "%0.4f" % mean_rpb]
          
          t.row [_("Variances mean"),  "%g" % @variances_mean]
          t.row [_("Covariances mean") , "%g" % @covariances_mean]
          end
          
          if (@alpha)
            s.text _("Items for obtain alpha(0.8) : %d" % Statsample::Reliability::n_for_desired_reliability(@alpha, 0.8, @ds.ncols))
            s.text _("Items for obtain alpha(0.9) : %d" % Statsample::Reliability::n_for_desired_reliability(@alpha, 0.9, @ds.ncols))
          end
          
          
          sid=stats_if_deleted
          is=item_statistics
          itc=item_total_correlation
          
          s.table(:name=>_("Items report for %s") % @name, :header=>["item","mean","sd", "mean if deleted", "var if deleted", "sd if deleted"," item-total correl.", "alpha if deleted"]) do |t|
            @ds.vectors.each do |f|
              row=["#{@ds[f].name}(#{f})"]
              if is[f]
                row+=[sprintf("%0.5f",is[f][:mean]), sprintf("%0.5f", is[f][:sds])]
              else
                row+=["-","-"]
              end
              if sid[f]
                row+= [sprintf("%0.5f",sid[f][:mean]), sprintf("%0.5f",sid[f][:variance_sample]), sprintf("%0.5f",sid[f][:sds])]
              else
                row+=%w{- - -}
              end
              if itc[f]
                row+= [sprintf("%0.5f",itc[f])]
              else 
                row+=['-']
              end
              if sid[f] and !sid[f][:alpha].nil?
                row+=[sprintf("%0.5f",sid[f][:alpha])]
              else
                row+=["-"]
              end
              t.row row
            end # end each
          end # table
          s.parse_element(Statsample::Graph::Histogram.new(@total, :name=>"Histogram (valid data) for %s" % @name)) if @summary_histogram
        end # section
      end # def
    end # class
  end # module
end # module
