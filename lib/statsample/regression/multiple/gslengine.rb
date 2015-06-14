if Statsample.has_gsl?
  module Statsample
    module Regression
      module Multiple
        # Class for Multiple Regression Analysis
        # Requires rbgsl and uses a listwise aproach.
        # Slower on prediction of values than Alglib, because predict is ruby based.
        # Better memory management on multiple (+1000) series of regression.
        # If you need pairwise, use RubyEngine
        # Example:
        #
        #   @a = Daru::Vector.new([1,3,2,4,3,5,4,6,5,7])
        #   @b = Daru::Vector.new([3,3,4,4,5,5,6,6,4,4])
        #   @c = Daru::Vector.new([11,22,30,40,50,65,78,79,99,100])
        #   @y = Daru::Vector.new([3,4,5,6,7,8,9,10,20,30])
        #   ds = Daru::DataFrame.new({:a => @a,:b => @b,:c => @c,:y => @y})
        #   lr=Statsample::Regression::Multiple::GslEngine.new(ds,:y)
        #
        class GslEngine < BaseEngine
          def initialize(ds,y_var, opts=Hash.new)
            super
            @ds          = ds.dup_only_valid
            @ds_valid    = @ds
            @valid_cases = @ds_valid.nrows
            @dy          = @ds[@y_var]
            @ds_indep    = ds.dup(ds.vectors.to_a - [y_var])
            # Create a custom matrix
            columns=[]
            @fields=[]
            max_deps = GSL::Matrix.alloc(@ds.nrows, @ds.vectors.size)
            constant_col=@ds.vectors.size-1
            for i in 0...@ds.nrows
              max_deps.set(i,constant_col,1)
            end
            j = 0
            @ds.vectors.each do |f|
              if f != @y_var
                @ds[f].each_index do |i1|
                  max_deps.set(i1,j,@ds[f][i1])
                end

                columns.push(@ds[f].to_a)
                @fields.push(f)
                j += 1
              end
            end
            @dep_columns = columns.dup
            @lr_s        = nil
            c, @cov, @chisq, @status = GSL::MultiFit.linear(max_deps, @dy.to_gsl)
            @constant=c[constant_col]
            @coeffs_a=c.to_a.slice(0...constant_col)
            @coeffs=assign_names(@coeffs_a)
            c=nil
          end

          def _dump(i)
            Marshal.dump({'ds'=>@ds,'y_var'=>@y_var})
          end
          def self._load(data)
            h=Marshal.load(data)
            self.new(h['ds'], h['y_var'])
          end

          def coeffs
            @coeffs
          end
          # Coefficients using a constant
          # Based on http://www.xycoon.com/ols1.htm
          def matrix_resolution
            columns=@dep_columns.dup.map {|xi| xi.map{|i| i.to_f}}
            columns.unshift([1.0]*@ds.cases)
            y=Matrix.columns([@dy.data.map  {|i| i.to_f}])
            x=Matrix.columns(columns)
            xt=x.t
            matrix=((xt*x)).inverse*xt
            matrix*y
          end
          def r2
            r**2
          end
          def r
            Bivariate::pearson(@dy, predicted)
          end
          def sst
            @dy.ss
          end
          def constant
            @constant
          end
          def standarized_coeffs
            l=lr_s
            l.coeffs
          end
          def lr_s
            if @lr_s.nil?
              build_standarized
            end
            @lr_s
          end
          def build_standarized
            @ds_s=@ds.standardize
            @lr_s=GslEngine.new(@ds_s,@y_var)
          end
          def process_s(v)
            lr_s.process(v)
          end
          # ???? Not equal to SPSS output
          def standarized_residuals
            res=residuals
            red_sd=residuals.sds
            Daru::Vector.new(res.collect {|v| v.quo(red_sd) })
          end

          # Standard error for coeffs
          def coeffs_se
            out  = {}
            evcm = estimated_variance_covariance_matrix
            @ds_valid.vectors.to_a.each_with_index do |f,i|
              mi = i+1
              next if f == @y_var
              out[f] = evcm[mi,mi]
            end
            out
          end
        end
      end
    end
  end # for Statsample
end # for if
