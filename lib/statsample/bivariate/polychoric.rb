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
      ds.collect_matrix do |row,col|
        if row==col
          1.0
        else
          begin
            polychoric(ds[row],ds[col])
          rescue RuntimeError
            nil
          end
        end
      end
    end
    # Compute polychoric correlation.
    #
    # The polychoric correlation estimate what the correlation between raters, who classified on a ordered category scale,  would be if ratings were made on a continuous scale; they are, theoretically, invariant over changes in the number or "width" of rating categories. 
    # See extensive documentation on http://www.john-uebersax.com/stat/tetra.htm
    
    class Polychoric
      include GetText
      bindtextdomain("statsample")
      # Name of the analysis
      attr_accessor :name
      # Max number of iterations used on iterative methods. Default to 100
      attr_accessor :max_iterations
      # Debug algorithm (See iterations, for example)
      attr_accessor :debug
      # Minimizer type. Default GSL::Min::FMinimizer::BRENT
      # See http://rb-gsl.rubyforge.org/min.html for reference.  
      attr_accessor :minimizer_type
      # Method of calculation.
      #
      # Drasgow (1988, cited by Uebersax, 2002) describe two method: joint maximum likelihood (ML) approach and two-step ML estimation.
      # For now, only implemented two-step ML (:two_step), with algorithm
      # based on Drasgow(1986, cited by Gegenfurtner, 1992)
      #
      attr_accessor :method
      # Absolute error for iteration. Default to 0.001
      attr_accessor :epsilon
      
      # Number of iterations
      attr_reader :iteration
      
      # Log of algorithm
      attr_reader :log
      attr_reader :loglike
      MAX_ITERATIONS=100
      EPSILON=0.001
      MINIMIZER_TYPE=GSL::Min::FMinimizer::BRENT
      def new_with_vectors(v1,v2)
        Polychoric.new(Crosstab.new(v1,v2).to_matrix)
      end
      # Calculate Polychoric correlation
      # You should enter a Matrix with ordered data. For 
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
      #   poly=Statsample::Bivariate::Polychoric.new(matrix)
      #   puts poly.r
      
      
      def initialize(matrix, opts=Hash.new)
        @matrix=matrix
        @n=matrix.column_size
        @m=matrix.row_size
        raise "row size <1" if @m<=1
        raise "column size <1" if @n<=1
        
        @method=:two_step
        @name="Polychoric correlation"
        @max_iterations=MAX_ITERATIONS
        @epsilon=EPSILON
        @minimizer_type=GSL::Min::FMinimizer::BRENT
        @debug=false
        @iteration=nil
        opts.each{|k,v|
          self.send("#{k}=",v) if self.respond_to? k
        }
        @r=nil
      end
      def r
        if @r.nil?
          compute
        end
        @r
      end
      
      def threshold_x
        if @alpha.nil?
          compute
        end
        @alpha[0,@alpha.size-1]
      end
      
      def threshold_y
        if @beta.nil?
          compute
        end
        @beta[0,@beta.size-1]
      end
      
      
      # Start the computation of polychoric correlation
      # based on @method
      def compute
        if @method==:two_step
          compute_two_step_mle_drasgow
        elsif @method==:as87
          compute_two_step_as87
        else
          raise "Not implemented"
        end
      end
      # Computation of polychoric correlation usign two-step ML estimation.
      # 
      # Two-step ML estimation "first estimates the thresholds from the one-way marginal frequencies, then estimates rho, conditional on these thresholds, via maximum likelihood" (Uebersax, 2006).
      #
      # The algorithm is based on Drasgow(1986, cited by Gegenfurtner (1992).
      # <b>References</b>:
      # * Gegenfurtner, K. (1992). PRAXIS: Brent's algorithm for function minimization. Behavior Research Methods, Instruments & Computers, 24(4), 560-564. Available on http://www.allpsych.uni-giessen.de/karl/pdf/03.praxis.pdf
      # * Uebersax, J.S. (2006). The tetrachoric and polychoric correlation coefficients. Statistical Methods for Rater Agreement web site. 2006. Available at: http://john-uebersax.com/stat/tetra.htm . Accessed February, 11, 2010
      #
      def compute_two_step_mle_drasgow
        @nr=@matrix.row_size
        @nc=@matrix.column_size
        @sumr=[0]*@matrix.row_size
        @sumrac=[0]*@matrix.row_size
        @sumc=[0]*@matrix.column_size
        @sumcac=[0]*@matrix.column_size
        @alpha=[0]*@matrix.row_size
        @beta=[0]*@matrix.row_size
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
        @alpha[@nr-1]=10
        @beta[@nc-1]=10
        fn1=GSL::Function.alloc {|x| 
          loglike=0
          pd=@nr.times.collect{ [0]*@nc}
          pc=@nr.times.collect{ [0]*@nc}

          @nr.times { |i|
            @nc.times { |j|
              pd[i][j]=Distribution::NormalBivariate.cdf(@alpha[i], @beta[j], x)
              pc[i][j] = pd[i][j]
              pd[i][j] = pd[i][j] - pc[i-1][j] if i>0
              pd[i][j] = pd[i][j] - pc[i][j-1] if j>0
              pd[i][j] = pd[i][j] + pc[i-1][j-1] if (i>0 and j>0)
              res= pd[i][j]
              
              if res==0.0
                res=1e-15
               end 
               
              # puts "i:#{i} | j:#{j} | ac: #{sprintf("%0.4f", pc[i][j])} | pd: #{sprintf("%0.4f", pd[i][j])} | res:#{sprintf("%0.4f", res)}"
              loglike+= @matrix[i,j]  * Math::log( res )
            }
          }
          # p pd
          @loglike=loglike
          @pd=pd
          -loglike
        }
      @iteration = 0
      max_iter = @max_iterations
      m = 0             # initial guess
      m_expected = 0.5
      a=-0.99999
      b=+0.99999
      gmf = GSL::Min::FMinimizer.alloc(@minimizer_type)
      gmf.set(fn1, m, a, b)
      header=sprintf("using %s method\n", gmf.name)
      header+=sprintf("%5s [%9s, %9s] %9s %10s %9s\n", "iter", "lower", "upper", "min",
         "err", "err(est)")
        
      header+=sprintf("%5d [%.7f, %.7f] %.7f %+.7f %.7f\n", @iteration, a, b, m, m - m_expected, b - a)
      @log=header
      puts header if @debug
      begin
        @iteration += 1
        status = gmf.iterate
        status = gmf.test_interval(0.001, 0.0)
        
        if status == GSL::SUCCESS
          @log+="Converged:"
          puts "Converged:" if @debug
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
      end
      # Chi-square to test r=0
      def chi_square_independence # :nodoc:
        Statsample::Test::chi_square(@matrix, expected)
      end
      # Chi-square to test model==independence
      
      def chi_square_model_expected # :nodoc:
        calculate if @r.nil?
        model=Matrix.rows(@pd).collect {|c| c*@total}
        Statsample::Test::chi_square(model, expected)

      end
      # Chi-square to test real == calculated with rho
      def  chi_square_model # :nodoc:
        calculate if @r.nil?
        e=Matrix.rows(@pd).collect {|c| c*@total}
        Statsample::Test::chi_square(@matrix, e)
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
      def g2 # :nodoc:
        raise "Doesn't work"
        e=expected
        no_r_likehood=0
        @nr.times {|i|
          @nc.times {|j|
            #p @matrix[i,j]
            if @matrix[i,j]!=0
              no_r_likehood+= @matrix[i,j]*Math::log(e[i,j])
            end
          }
        }
        p no_r_likehood
        model=Matrix.rows(@pd).collect {|c| c*@total}

        model_likehood=0
        @nr.times {|i|
          @nc.times {|j|
            #p @matrix[i,j]
            if @matrix[i,j]!=0
              model_likehood+= @matrix[i,j] * Math::log(model[i,j])
            end
          }
        }
        
        p model_likehood
        
        -2*(no_r_likehood-model_likehood)
        
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
      # Compute polychoric using AS87.
      # Doesn't work for now! I can't find the error :(
      
      def compute_two_step_as87 # :nodoc:
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
        @alpha=alpha[1,alpha.size] << nil
        @beta=beta[1,beta.size] << nil
        @sumr=sumr
        @sumc=sumc
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
      
      def summary
        rp=ReportBuilder.new()
        rp.add(self)
        rp.to_text
      end
      
      def to_reportbuilder(generator)
        compute if @r.nil?
        section=ReportBuilder::Section.new(:name=>@name)
        t=ReportBuilder::Table.new(:name=>_("Contingence Table"),:header=>[""]+(@n.times.collect {|i| "Y=#{i}"})+["Total"])
        @m.times do |i|
          t.add_row(["X = #{i}"]+(@n.times.collect {|j| @matrix[i,j]}) + [@sumr[i]])
        end
        t.add_hr
        t.add_row(["T"]+(@n.times.collect {|j| @sumc[j]})+[@total])
        section.add(t)
        #generator.parse_element(t)
        section.add(sprintf("r: %0.4f",r))
        t=ReportBuilder::Table.new(:name=>_("Thresholds"), :header=>["","Value"])
        threshold_x.each_with_index {|val,i|
          t.add_row(["Threshold X #{i}", sprintf("%0.4f", val)])
        }
        threshold_y.each_with_index {|val,i|
          t.add_row(["Threshold Y #{i}", sprintf("%0.4f", val)])
        }
        section.add(t)
        generator.parse_element(section)
      end
    end
  end
end
