require 'minimization'
module Statsample
  module Bivariate
    # Calculate Polychoric correlation for two vectors.
    def self.polychoric(v1,v2)
      pc=Polychoric.new_with_vectors(v1,v2)
      pc.r
    end
    
    # Polychoric correlation matrix.
    # Order of rows and columns depends on Dataset#fields order
    def self.polychoric_correlation_matrix(ds)
      cache={}
      matrix=ds.collect_matrix do |row,col|
        if row==col
          1.0
        else
          begin
            if cache[[col,row]].nil?
              poly=polychoric(ds[row],ds[col])
              cache[[row,col]]=poly
              poly
            else
              cache[[col,row]]
            end
          rescue RuntimeError
            nil
          end
        end
      end
      matrix.extend CovariateMatrix
      matrix.fields=ds.fields
      matrix
    end
    
    # = Polychoric correlation.
    #
    # The <em>polychoric</em> correlation is a measure of 
    # bivariate association arising when both observed variates
    # are ordered, categorical variables that result from polychotomizing
    # the two undelying continuous variables (Drasgow, 2006)
    # 
    # According to Drasgow(2006), there are tree methods to estimate
    # the polychoric correlation: 
    #
    # 1. Maximum Likehood Estimator
    # 2. Two-step estimator and 
    # 3. Polychoric series estimate. 
    # 
    # By default, two-step estimation are used. You can select 
    # the estimation method with method attribute. Joint estimate and polychoric series requires gsl library and rb-gsl.
    #
    # == Use
    #
    # You should enter a Matrix with ordered data. For example:
    #         -------------------
    #         | y=0 | y=1 | y=2 | 
    #         -------------------
    #   x = 0 |  1  |  10 | 20  |
    #         -------------------
    #   x = 1 |  20 |  20 | 50  |
    #         -------------------
    # 
    # The code will be
    #
    #   matrix=Matrix[[1,10,20],[20,20,50]]
    #   poly=Statsample::Bivariate::Polychoric.new(matrix, :method=>:joint)
    #   puts poly.r
    # 
    # See extensive documentation on Uebersax(2002) and Drasgow(2006)
    #
    # == References 
    # 
    # * Uebersax, J.S. (2006). The tetrachoric and polychoric correlation coefficients. Statistical Methods for Rater Agreement web site. 2006. Available at: http://john-uebersax.com/stat/tetra.htm . Accessed February, 11, 2010
    # * Drasgow F. (2006). Polychoric and polyserial correlations. In Kotz L, Johnson NL (Eds.), Encyclopedia of statistical sciences. Vol. 7 (pp. 69-74). New York: Wiley.
    
    class Polychoric
      include Summarizable
      class Processor
        attr_reader :alpha, :beta, :rho
        def initialize(alpha,beta,rho)
          @alpha=alpha
          @beta=beta
          @nr=@alpha.size+1
          @nc=@beta.size+1
          @rho=rho
          @pd=nil
        end
        def bipdf(i,j)
           Distribution::NormalBivariate.pdf(a(i), b(j), rho)
        end
        def a(i)
          i < 0 ? -100 : (i==@nr-1 ? 100 : alpha[i])
        end
        def b(j)
          j < 0 ? -100 : (j==@nc-1 ? 100 : beta[j])
        end
        # Equation(10) from Olsson(1979)
        def fd_loglike_cell_a(i,j,k)
          if k==i
            Distribution::NormalBivariate.pd_cdf_x(a(k),b(j), rho) - Distribution::NormalBivariate.pd_cdf_x(a(k),b(j-1),rho)
          elsif k==(i-1)
            -Distribution::NormalBivariate.pd_cdf_x(a(k),b(j),rho) + Distribution::NormalBivariate.pd_cdf_x(a(k),b(j-1),rho)
          else
            0
          end
          
        end
        # phi_ij for each i and j
        # Uses equation(4) from Olsson(1979)
        def pd
          if @pd.nil?
            @pd=@nr.times.collect{ [0] * @nc}
            pc=@nr.times.collect{ [0] * @nc}
            @nr.times do |i|
            @nc.times do |j|
             
              if i==@nr-1 and j==@nc-1
                @pd[i][j]=1.0
              else
                a=(i==@nr-1) ? 100: alpha[i]
                b=(j==@nc-1) ? 100: beta[j]
                #puts "a:#{a} b:#{b}"
                @pd[i][j]=Distribution::NormalBivariate.cdf(a, b, rho)
              end
              pc[i][j] = @pd[i][j]
              @pd[i][j] = @pd[i][j] - pc[i-1][j] if i>0
              @pd[i][j] = @pd[i][j] - pc[i][j-1] if j>0
              @pd[i][j] = @pd[i][j] + pc[i-1][j-1] if (i>0 and j>0)
            end
            end
          end
          @pd
        end
      end
      
      include DirtyMemoize
      # Name of the analysis
      attr_accessor :name
      # Max number of iterations used on iterative methods. Default to MAX_ITERATIONS
      attr_accessor :max_iterations
      # Debug algorithm (See iterations, for example)
      attr_accessor :debug
      # Minimizer type for two step. Default "brent"
      # See http://rb-gsl.rubyforge.org/min.html for reference.  
      attr_accessor :minimizer_type_two_step
      
      # Minimizer type for joint estimate. Default "nmsimplex"
      # See http://rb-gsl.rubyforge.org/min.html for reference.  
      attr_accessor :minimizer_type_joint
      
      
      # Method of calculation of polychoric series. 
      # <tt>:two_step</tt> used by default.
      # 
      # :two_step:: two-step ML, based on code by Gegenfurtner(1992).
      # :polychoric_series:: polychoric series estimate, using 
      #                      algorithm AS87 by Martinson and Hamdan (1975).
      # :joint::             one-step ML, based on R package 'polycor'
      #                      by J.Fox.
      attr_accessor :method
      # Absolute error for iteration.
      attr_accessor :epsilon
      
      # Number of iterations
      attr_reader :iteration
      
      # Log of algorithm
      attr_reader :log
      
      
      attr_reader :loglike_model
      
      METHOD=:two_step
      MAX_ITERATIONS=300
      EPSILON=1e-6
      MINIMIZER_TYPE_TWO_STEP="brent"
      MINIMIZER_TYPE_JOINT="nmsimplex"
      def self.new_with_vectors(v1,v2)
        Polychoric.new(Crosstab.new(v1,v2).to_matrix)
      end
      # Params:
      # * matrix: Contingence table
      # * opts: Any attribute

      def initialize(matrix, opts=Hash.new)
        @matrix=matrix
        @n=matrix.column_size
        @m=matrix.row_size
        raise "row size <1" if @m<=1
        raise "column size <1" if @n<=1
        
        @method=METHOD
        @name=_("Polychoric correlation")
        @max_iterations=MAX_ITERATIONS
        @epsilon=EPSILON
        @minimizer_type_two_step=MINIMIZER_TYPE_TWO_STEP
        @minimizer_type_joint=MINIMIZER_TYPE_JOINT
        @debug=false
        @iteration=nil
        opts.each{|k,v|
          self.send("#{k}=",v) if self.respond_to? k
        }
        @r=nil
        @pd=nil
        compute_basic_parameters
      end
      # Returns the polychoric correlation
      attr_reader :r
      # Returns the rows thresholds
      attr_reader :alpha
      # Returns the columns thresholds
      attr_reader :beta
      
      dirty_writer :max_iterations, :epsilon, :minimizer_type_two_step, :minimizer_type_joint, :method
      dirty_memoize :r, :alpha, :beta
      
      alias :threshold_x :alpha
      alias :threshold_y :beta
      
      
      # Start the computation of polychoric correlation
      # based on attribute method
      def compute
        if @method==:two_step
          compute_two_step_mle_drasgow
        elsif @method==:joint
          compute_one_step_mle
        elsif @method==:polychoric_series
          compute_polychoric_series
        else
          raise "Not implemented"
        end
      end
      # Retrieve log likehood for actual data.
      def loglike_data
        loglike=0
        @nr.times do |i|
          @nc.times do |j|
            res=@matrix[i,j].quo(@total)
            if (res==0)
              res=1e-16
            end
          loglike+= @matrix[i,j]  * Math::log(res )
          end
        end
        loglike
      end
      
      # Chi Square of model
      def chi_square
        if @loglike_model.nil?
          compute
        end
        -2*(@loglike_model-loglike_data)
      end
      
      def chi_square_df
        (@nr*@nc)-@nc-@nr
      end




      # Retrieve all cell probabilities for givens alpha, beta and rho
      def cell_probabilities(alpha,beta,rho)
        pd=@nr.times.collect{ [0] * @nc}
        pc=@nr.times.collect{ [0] * @nc}
        @nr.times do |i|
          @nc.times do |j|
           
            if i==@nr-1 and j==@nc-1
              pd[i][j]=1.0
            else
              a=(i==@nr-1) ? 100: alpha[i]
              b=(j==@nc-1) ? 100: beta[j]
              #puts "a:#{a} b:#{b}"
              pd[i][j]=Distribution::NormalBivariate.cdf(a, b, rho)
            end
            pc[i][j] = pd[i][j]
            pd[i][j] = pd[i][j] - pc[i-1][j] if i>0
            pd[i][j] = pd[i][j] - pc[i][j-1] if j>0
            pd[i][j] = pd[i][j] + pc[i-1][j-1] if (i>0 and j>0)
          end
        end
        @pd=pd
        pd
      end
      def loglike(alpha,beta,rho)
        if rho.abs>0.9999
          rho= (rho>0) ? 0.9999 : -0.9999
        end
        pr=Processor.new(alpha,beta,rho)
        loglike=0

        
        @nr.times do |i|
          @nc.times do |j|
            res=pr.pd[i][j]+EPSILON
            loglike+= @matrix[i,j]  * Math::log( res )
          end
        end
        -loglike
      end
      # First derivate for rho
      # Uses equation (9) from Olsson(1979)
      def fd_loglike_rho(alpha,beta,rho)
        if rho.abs>0.9999
          rho= (rho>0) ? 0.9999 : -0.9999
        end
        total=0
        pr=Processor.new(alpha,beta,rho)
        @nr.times do |i|
          @nc.times do |j|
            pi=pr.pd[i][j] + EPSILON
            total+= (@matrix[i,j] / pi)  * (pr.bipdf(i,j)-pr.bipdf(i-1,j)-pr.bipdf(i,j-1)+pr.bipdf(i-1,j-1))  
          end
        end
        total
      end
      
      # First derivative for alpha_k
      def fd_loglike_a(alpha,beta,rho,k)
        fd_loglike_a_eq6(alpha,beta,rho,k)
      end
      # Uses equation (6) from Olsson(1979)
      def fd_loglike_a_eq6(alpha,beta,rho,k)
        if rho.abs>0.9999
          rho= (rho>0) ? 0.9999 : -0.9999
        end
        pr=Processor.new(alpha,beta,rho)
        total=0
        pd=pr.pd
        @nr.times do |i|
          @nc.times  do |j|
            total+=@matrix[i,j].quo(pd[i][j]+EPSILON) * pr.fd_loglike_cell_a(i,j,k)
          end
        end
        total
      end
      # Uses equation(13) from Olsson(1979)
      def fd_loglike_a_eq13(alpha,beta,rho,k)
        if rho.abs>0.9999
          rho= (rho>0) ? 0.9999 : -0.9999
        end
        pr=Processor.new(alpha,beta,rho)
        total=0
        a_k=pr.a(k)
        pd=pr.pd
        @nc.times do |j|
          #puts "j: #{j}"
          #puts "b #{j} : #{b.call(j)}"
          #puts "b #{j-1} : #{b.call(j-1)}"

          e_1=@matrix[k,j].quo(pd[k][j]+EPSILON) - @matrix[k+1,j].quo(pd[k+1][j]+EPSILON)
          e_2=Distribution::Normal.pdf(a_k)
          e_3=Distribution::Normal.cdf((pr.b(j)-rho*a_k).quo(Math::sqrt(1-rho**2))) - Distribution::Normal.cdf((pr.b(j-1)-rho*a_k).quo(Math::sqrt(1-rho**2)))
          #puts "val #{j}: #{e_1} | #{e_2} | #{e_3}"
          
          total+= e_1*e_2*e_3
        end
        total
      end
      # First derivative for beta_m
      # Uses equation(14) from Olsson(1979)
      def fd_loglike_b(alpha,beta,rho,m)
        if rho.abs>0.9999
          rho= (rho>0) ? 0.9999 : -0.9999
        end
        pr=Processor.new(alpha,beta,rho)
        total=0
        b_m=pr.b m
        pd=pr.pd
        @nr.times do |i|
          #puts "j: #{j}"
          #puts "b #{j} : #{b.call(j)}"
          #puts "b #{j-1} : #{b.call(j-1)}"

          e_1=@matrix[i,m].quo(pd[i][m]+EPSILON) - @matrix[i,m+1].quo(pd[i][m+1]+EPSILON)
          e_2=Distribution::Normal.pdf(b_m)
          e_3=Distribution::Normal.cdf((pr.a(i)-rho*b_m).quo(Math::sqrt(1-rho**2))) - Distribution::Normal.cdf((pr.a(i-1)-rho*b_m).quo(Math::sqrt(1-rho**2)))
          #puts "val #{j}: #{e_1} | #{e_2} | #{e_3}"
          
          total+= e_1*e_2*e_3
        end
        total
      end
      
      
      def compute_basic_parameters
        @nr=@matrix.row_size
        @nc=@matrix.column_size
        @sumr=[0]*@matrix.row_size
        @sumrac=[0]*@matrix.row_size
        @sumc=[0]*@matrix.column_size
        @sumcac=[0]*@matrix.column_size
        @alpha=[0]*(@nr-1)
        @beta=[0]*(@nc-1)
        @total=0
        @nr.times do |i|
          @nc.times do |j|
            @sumr[i]+=@matrix[i,j]
            @sumc[j]+=@matrix[i,j]
            @total+=@matrix[i,j]
          end
        end
        ac=0
        (@nr-1).times do |i|
          @sumrac[i]=@sumr[i]+ac
          @alpha[i]=Distribution::Normal.p_value(@sumrac[i] / @total.to_f)
          ac=@sumrac[i]
        end
        ac=0
        (@nc-1).times do |i|
          @sumcac[i]=@sumc[i]+ac
          @beta[i]=Distribution::Normal.p_value(@sumcac[i] / @total.to_f)
          ac=@sumcac[i]
        end
      end
      
      
      # Computation of polychoric correlation usign two-step ML estimation.
      # 
      # Two-step ML estimation "first estimates the thresholds from the one-way marginal frequencies, then estimates rho, conditional on these thresholds, via maximum likelihood" (Uebersax, 2006).
      #
      # The algorithm is based on code by Gegenfurtner(1992).
      # 
      # <b>References</b>:
      # * Gegenfurtner, K. (1992). PRAXIS: Brent's algorithm for function minimization. Behavior Research Methods, Instruments & Computers, 24(4), 560-564. Available on http://www.allpsych.uni-giessen.de/karl/pdf/03.praxis.pdf
      # * Uebersax, J.S. (2006). The tetrachoric and polychoric correlation coefficients. Statistical Methods for Rater Agreement web site. 2006. Available at: http://john-uebersax.com/stat/tetra.htm . Accessed February, 11, 2010
      #
      def compute_two_step_mle_drasgow
        if Statsample.has_gsl?
          compute_two_step_mle_drasgow_gsl
        else
          compute_two_step_mle_drasgow_ruby
        end
      end
      
      # Depends on minimization algorithm. 
      
      def compute_two_step_mle_drasgow_ruby #:nodoc:
        
        f=proc {|rho|
          loglike(@alpha,@beta, rho)
        }
        @log=_("Minimizing using GSL Brent method\n")
        min=Minimization::Brent.new(-0.9999,0.9999,f)
        min.epsilon=@epsilon
        min.expected=0
        min.iterate
        @log+=min.log.to_table.to_s
        @r=min.x_minimum
        @loglike_model=-min.f_minimum
        puts @log if @debug
        
      end
      
      
      def compute_two_step_mle_drasgow_gsl #:nodoc:
        
      fn1=GSL::Function.alloc {|rho| 
        loglike(@alpha,@beta, rho)
      }
      @iteration = 0
      max_iter = @max_iterations
      m = 0             # initial guess
      m_expected = 0
      a=-0.9999
      b=+0.9999
      gmf = GSL::Min::FMinimizer.alloc(@minimizer_type_two_step)
      gmf.set(fn1, m, a, b)
      header=_("Two step minimization using %s method\n") % gmf.name
      header+=sprintf("%5s [%9s, %9s] %9s %10s %9s\n", "iter", "lower", "upper", "min",
         "err", "err(est)")
        
      header+=sprintf("%5d [%.7f, %.7f] %.7f %+.7f %.7f\n", @iteration, a, b, m, m - m_expected, b - a)
      @log=header
      puts header if @debug
      begin
        @iteration += 1
        status = gmf.iterate
        status = gmf.test_interval(@epsilon, 0.0)
        
        if status == GSL::SUCCESS
          @log+="converged:"
          puts "converged:" if @debug
        end
        a = gmf.x_lower
        b = gmf.x_upper
        m = gmf.x_minimum
        message=sprintf("%5d [%.7f, %.7f] %.7f %+.7f %.7f\n",
          @iteration, a, b, m, m - m_expected, b - a);
        @log+=message
        puts message if @debug
      end while status == GSL::CONTINUE and @iteration < @max_iterations
      @r=gmf.x_minimum
      @loglike_model=-gmf.f_minimum
      end
      
      # Compute Polychoric correlation with joint estimate.
      # Rho and thresholds are estimated at same time.
      # Code based on R package "polycor", by J.Fox.
      #
      
      def compute_one_step_mle
        # Get initial values with two-step aproach
        compute_two_step_mle_drasgow
        # Start iteration with past values
        rho=@r
        cut_alpha=@alpha
        cut_beta=@beta
        parameters=[rho]+cut_alpha+cut_beta
        minimization = Proc.new { |v, params|
         rho=v[0]
         alpha=v[1, @nr-1]
         beta=v[@nr, @nc-1]
         
         #puts "f'rho=#{fd_loglike_rho(alpha,beta,rho)}"
         #(@nr-1).times {|k|
         #  puts "f'a(#{k}) = #{fd_loglike_a(alpha,beta,rho,k)}"         
         #  puts "f'a(#{k}) v2 = #{fd_loglike_a2(alpha,beta,rho,k)}"         
         #
         #}
         #(@nc-1).times {|k|
         #  puts "f'b(#{k}) = #{fd_loglike_b(alpha,beta,rho,k)}"         
         #}
         
         loglike(alpha,beta,rho)
        }
        np=@nc-1+@nr
        my_func = GSL::MultiMin::Function.alloc(minimization, np)
        my_func.set_params(parameters)      # parameters
        
        x = GSL::Vector.alloc(parameters.dup)
        
        ss = GSL::Vector.alloc(np)
        ss.set_all(1.0)
        
        minimizer = GSL::MultiMin::FMinimizer.alloc(minimizer_type_joint,np)
        minimizer.set(my_func, x, ss)
        
        iter = 0
        message=""
        begin
          iter += 1
          status = minimizer.iterate()
          status = minimizer.test_size(@epsilon)
          if status == GSL::SUCCESS
            message="Joint MLE converged to minimum at\n"
          end
          x = minimizer.x
          message+= sprintf("%5d iterations", iter)+"\n";
          for i in 0...np do
            message+=sprintf("%10.3e ", x[i])
          end
          message+=sprintf("f() = %7.3f size = %.3f\n", minimizer.fval, minimizer.size)+"\n";
        end while status == GSL::CONTINUE and iter < @max_iterations
        @iteration=iter
        @log+=message        
        @r=minimizer.x[0]
        @alpha=minimizer.x[1,@nr-1].to_a
        @beta=minimizer.x[@nr,@nc-1].to_a
        @loglike_model= -minimizer.minimum
      end

      def matrix_for_rho(rho) # :nodoc:
        pd=@nr.times.collect{ [0]*@nc}
        pc=@nr.times.collect{ [0]*@nc}
        @nr.times { |i|
            @nc.times { |j|
              pd[i][j]=Distribution::NormalBivariate.cdf(@alpha[i], @beta[j], rho)
              pc[i][j] = pd[i][j]
              pd[i][j] = pd[i][j] - pc[i-1][j] if i>0
              pd[i][j] = pd[i][j] - pc[i][j-1] if j>0
              pd[i][j] = pd[i][j] + pc[i-1][j-1] if (i>0 and j>0)
              res= pd[i][j]
            }
         }
         Matrix.rows(pc)
      end
      
      def expected # :nodoc:
        rt=[]
        ct=[]
        t=0
        @matrix.row_size.times {|i|
          @matrix.column_size.times {|j|
            rt[i]=0 if rt[i].nil?
            ct[j]=0 if ct[j].nil?
            rt[i]+=@matrix[i,j]
            ct[j]+=@matrix[i,j]
            t+=@matrix[i,j]
          }
        }
        m=[]
        @matrix.row_size.times {|i|
          row=[]
          @matrix.column_size.times {|j|
            row[j]=(rt[i]*ct[j]).quo(t)
          }
          m.push(row)
        }
        
        Matrix.rows(m)
      end
      
      # Compute polychoric correlation using polychoric series.
      # Algorithm: AS87, by Martinson and Hamdam(1975).
      # 
      # <b>Warning</b>: According to Drasgow(2006), this
      # computation diverges greatly of joint and two-step methods.
      # 
      def compute_polychoric_series 
        @nn=@n-1
        @mm=@m-1
        @nn7=7*@nn
        @mm7=7*@mm
        @mn=@n*@m
        @cont=[nil]
        @n.times {|j|
          @m.times {|i|
            @cont.push(@matrix[i,j])
          }
        }

        pcorl=0
        cont=@cont
        xmean=0.0
        sum=0.0
        row=[]
        colmn=[]
        (1..@m).each do |i|
          row[i]=0.0
          l=i
          (1..@n).each do |j|
            row[i]=row[i]+cont[l]
            l+=@m
          end
          raise "Should not be empty rows" if(row[i]==0.0)
          xmean=xmean+row[i]*i.to_f
          sum+=row[i]
        end
        xmean=xmean/sum.to_f
        ymean=0.0
        (1..@n).each do |j|
          colmn[j]=0.0
          l=(j-1)*@m
          (1..@m).each do |i|
            l=l+1
            colmn[j]=colmn[j]+cont[l] #12
          end
          raise "Should not be empty cols" if colmn[j]==0
          ymean=ymean+colmn[j]*j.to_f
        end
        ymean=ymean/sum.to_f
        covxy=0.0
        (1..@m).each do |i|
          l=i
          (1..@n).each do |j|
            conxy=covxy+cont[l]*(i.to_f-xmean)*(j.to_f-ymean)
            l=l+@m
          end
        end
        
        chisq=0.0
        (1..@m).each do |i|
          l=i
          (1..@n).each do |j|
            chisq=chisq+((cont[l]**2).quo(row[i]*colmn[j]))
            l=l+@m
          end
        end
        
        phisq=chisq-1.0-(@mm*@nn).to_f / sum.to_f
        phisq=0 if(phisq<0.0) 
        # Compute cumulative sum of columns and rows
        sumc=[]
        sumr=[]
        sumc[1]=colmn[1]
        sumr[1]=row[1]
        cum=0
        (1..@nn).each do |i| # goto 17 r20
          cum=cum+colmn[i]
          sumc[i]=cum
        end
        cum=0
        (1..@mm).each do |i| 
          cum=cum+row[i]
          sumr[i]=cum
        end
        alpha=[]
        beta=[]
        # Compute points of polytomy
        (1..@mm).each do |i| #do 21
          alpha[i]=Distribution::Normal.p_value(sumr[i] / sum.to_f)
        end # 21
        (1..@nn).each do |i| #do 22
          beta[i]=Distribution::Normal.p_value(sumc[i] / sum.to_f)
        end # 21
        @alpha=alpha[1,alpha.size] 
        @beta=beta[1,beta.size]
        @sumr=row[1,row.size]
        @sumc=colmn[1,colmn.size]
        @total=sum
        
        # Compute Fourier coefficients a and b. Verified
        h=hermit(alpha,@mm)
        hh=hermit(beta,@nn)
        a=[]
        b=[]
        if @m!=2 # goto 24
          mmm=@m-2
          (1..mmm).each do |i| #do 23
            a1=sum.quo(row[i+1] * sumr[i] * sumr[i+1])
            a2=sumr[i]   * xnorm(alpha[i+1])
            a3=sumr[i+1] * xnorm(alpha[i])
            l=i
            (1..7).each do |j| #do 23
              a[l]=Math::sqrt(a1.quo(j))*(h[l+1] * a2 - h[l] * a3)
              l=l+@mm
            end
          end #23
        end
        # 24
        
        
        if @n!=2 # goto 26
          nnn=@n-2
          (1..nnn).each do |i| #do 25
            a1=sum.quo(colmn[i+1] * sumc[i] * sumc[i+1])
            a2=sumc[i] * xnorm(beta[i+1])
            a3=sumc[i+1] * xnorm(beta[i])
            l=i
            (1..7).each do |j| #do 25
              b[l]=Math::sqrt(a1.quo(j))*(a2 * hh[l+1] - a3*hh[l])
              l=l+@nn
            end # 25
          end # 25
        end
        #26 r20
        l = @mm
        a1 = -sum * xnorm(alpha[@mm])
        a2 = row[@m] * sumr[@mm] 
        (1..7).each do |j| # do 27
          a[l]=a1 * h[l].quo(Math::sqrt(j*a2))
          l=l+@mm
        end # 27
        
        l = @nn
        a1 = -sum * xnorm(beta[@nn])
        a2 = colmn[@n] * sumc[@nn]

        (1..7).each do |j| # do 28
          b[l]=a1 * hh[l].quo(Math::sqrt(j*a2))
          l = l + @nn
        end # 28
        rcof=[]
        # compute coefficients rcof of polynomial of order 8
        rcof[1]=-phisq
        (2..9).each do |i| # do 30
          rcof[i]=0.0
        end #30 
        m1=@mm
        (1..@mm).each do |i| # do 31
          m1=m1+1
          m2=m1+@mm
          m3=m2+@mm
          m4=m3+@mm
          m5=m4+@mm
          m6=m5+@mm
          n1=@nn
          (1..@nn).each do |j| # do 31
            n1=n1+1
            n2=n1+@nn
            n3=n2+@nn
            n4=n3+@nn
            n5=n4+@nn
            n6=n5+@nn
            
            rcof[3] = rcof[3] + a[i]**2 * b[j]**2
            
            rcof[4] = rcof[4] + 2.0 * a[i] * a[m1] * b[j] * b[n1]
            
            rcof[5] = rcof[5] + a[m1]**2 * b[n1]**2 +
              2.0 * a[i] * a[m2] * b[j] * b[n2]
            
            rcof[6] = rcof[6] + 2.0 * (a[i] * a[m3] * b[j] *
              b[n3] + a[m1] * a[m2] * b[n1] * b[n2])
            
            rcof[7] = rcof[7] + a[m2]**2 * b[n2]**2 +
              2.0 * (a[i] * a[m4] * b[j] * b[n4] + a[m1] * a[m3] *
                b[n1] * b[n3])
            
            rcof[8] = rcof[8] + 2.0 * (a[i] * a[m5] * b[j] * b[n5] +
              a[m1] * a[m4] * b[n1] * b[n4] + a[m2] *  a[m3] * b[n2] * b[n3])
            
            rcof[9] = rcof[9] + a[m3]**2 * b[n3]**2 +
              2.0 * (a[i] * a[m6] * b[j] * b[n6] + a[m1] * a[m5] * b[n1] *
              b[n5] + (a[m2] * a[m4] * b[n2] * b[n4]))
          end # 31
        end # 31

        rcof=rcof[1,rcof.size]
        poly = GSL::Poly.alloc(rcof)
        roots=poly.solve
        rootr=[nil]
        rooti=[nil]
        roots.each {|c|
          rootr.push(c.real)
          rooti.push(c.im)
        }
        @rootr=rootr
        @rooti=rooti
        
        norts=0
        (1..7).each do |i| # do 43
          
          next if rooti[i]!=0.0 
          if (covxy>=0.0)
            next if(rootr[i]<0.0 or rootr[i]>1.0)
            pcorl=rootr[i]
            norts=norts+1
          else
            if (rootr[i]>=-1.0 and rootr[i]<0.0)
              pcorl=rootr[i]
              norts=norts+1              
            end
          end
        end # 43
        raise "Error" if norts==0
        @r=pcorl
        
        @loglike_model=-loglike(@alpha, @beta, @r)
        
      end
      #Computes vector h(mm7) of orthogonal hermite...
      def hermit(s,k) # :nodoc:
        h=[]
        (1..k).each do |i| # do 14
          l=i
          ll=i+k
          lll=ll+k
          h[i]=1.0
          h[ll]=s[i]
          v=1.0
          (2..6).each do |j| #do 14
            w=Math::sqrt(j)
            h[lll]=(s[i]*h[ll] - v*h[l]).quo(w)
            v=w
            l=l+k
            ll=ll+k
            lll=lll+k
          end
        end
        h
      end
      def xnorm(t) # :nodoc:
        Math::exp(-0.5 * t **2) * (1.0/Math::sqrt(2*Math::PI))
      end
      
      def report_building(generator) # :nodoc: 
        compute if dirty?
        section=ReportBuilder::Section.new(:name=>@name)
        t=ReportBuilder::Table.new(:name=>_("Contingence Table"), :header=>[""]+(@n.times.collect {|i| "Y=#{i}"})+["Total"])
        @m.times do |i|
          t.row(["X = #{i}"]+(@n.times.collect {|j| @matrix[i,j]}) + [@sumr[i]])
        end
        t.hr
        t.row(["T"]+(@n.times.collect {|j| @sumc[j]})+[@total])
        section.add(t)
        section.add(sprintf("r: %0.4f",r))
        t=ReportBuilder::Table.new(:name=>_("Thresholds"), :header=>["","Value"])
        threshold_x.each_with_index {|val,i|
          t.row([_("Threshold X %d") % i, sprintf("%0.4f", val)])
        }
        threshold_y.each_with_index {|val,i|
          t.row([_("Threshold Y %d") % i, sprintf("%0.4f", val)])
        }
        section.add(t)
        section.add(_("Test of bivariate normality: X2 = %0.3f, df = %d, p= %0.5f" % [ chi_square, chi_square_df, 1-Distribution::ChiSquare.cdf(chi_square, chi_square_df)])) 
        generator.parse_element(section)
      end
    end
  end
end
