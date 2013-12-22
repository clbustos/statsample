module Statsample
  module Regression
    # Class for calculation of linear regressions with form
    #   y = a+bx
    # To create a Statsample::Regression::Simple object:
    # * <tt> Statsample::Regression::Simple.new_from_dataset(ds,x,y)</tt>
    # * <tt> Statsample::Regression::Simple.new_from_vectors(vx,vy)</tt>
    # * <tt> Statsample::Regression::Simple.new_from_gsl(gsl) </tt>
    #
    class Simple
      include Summarizable
      attr_accessor :a,:b,:cov00, :cov01, :covx1, :chisq, :status
      attr_accessor :name
      attr_accessor :digits
      def initialize(init_method, *argv)
        self.send(init_method, *argv)
      end
      private_class_method :new
      # Obtain y value given x value
      # x=a+bx

      def y(val_x)
        @a+@b*val_x
      end
      # Obtain x value given y value
      # x=(y-a)/b
      def x(val_y)
        (val_y-@a) / @b.to_f
      end
      # Sum of square error
      def sse
        (0...@vx.size).inject(0) {|acum,i| acum+((@vy[i]-y(@vx[i]))**2)
        }
      end
      def standard_error
        Math::sqrt(sse / (@vx.size-2).to_f)
      end
      # Sum of square regression
      def ssr
        vy_mean=@vy.mean
        (0...@vx.size).inject(0) {|a,i|
          a+((y(@vx[i])-vy_mean)**2)
        }

      end
      # Sum of square total
      def sst
        @vy.sum_of_squared_deviation
      end
      # Value of r
      def r
        @b * (@vx.sds / @vy.sds)
      end
      # Value of r^2
      def r2
        r**2
      end
      class << self
        # Create a regression object giving an array with following parameters:
        # <tt>a,b,cov00, cov01, covx1, chisq, status</tt>
        # Useful to obtain x and y values with a and b values.
        def new_from_gsl(ar)
          new(:init_gsl, *ar)
        end
        # Create a simple regression using two vectors
        def new_from_vectors(vx,vy, opts=Hash.new)
          new(:init_vectors,vx,vy, opts)
        end
        # Create a simple regression using a dataset and two vector names.
        def new_from_dataset(ds,x,y, opts=Hash.new)
          new(:init_vectors,ds[x],ds[y], opts)
        end
      end
      def init_vectors(vx,vy, opts=Hash.new)
        @vx,@vy=Statsample.only_valid_clone(vx,vy)
        x_m=@vx.mean
        y_m=@vy.mean
        num=den=0
        (0...@vx.size).each {|i|
          num+=(@vx[i]-x_m)*(@vy[i]-y_m)
          den+=(@vx[i]-x_m)**2
        }
        @b=num.to_f/den
        @a=y_m - @b*x_m
        
        opts_default={
        :digits=>3, 
        :name=>_("Regression of %s over %s") % [@vx.name, @vy.name]
         }
        @opts=opts_default.merge opts

        @opts.each{|k,v|
          self.send("#{k}=",v) if self.respond_to? k
        }
        
      end
      def init_gsl(a,b,cov00, cov01, covx1, chisq, status)
        @a=a
        @b=b
        @cov00=cov00
        @cov01=cov01
        @covx1=covx1
        @chisq=chisq
        @status=status
      end
      def report_building(gen)
      f="%0.#{digits}f"
        gen.section(:name=>name) do |s|
          s.table(:header=>[_("Variable"), _("Value")]) do |t|
            t.row [_("r"), f % r]
            t.row [_("r^2"), f % r2]
            t.row [_("a"), f % a]
            t.row [_("b"), f % b]
            t.row [_("s.e"), f % standard_error]
          end
        end
      end
      private :init_vectors, :init_gsl
    end
  end
end
