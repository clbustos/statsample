require 'statsample/bivariate/pearson'
module Statsample
  # Diverse methods and classes to calculate bivariate relations
  # Specific classes: 
  # * Statsample::Bivariate::Pearson : Pearson correlation coefficient (r)
  # * Statsample::Bivariate::Tetrachoric : Tetrachoric correlation
  # * Statsample::Bivariate::Polychoric  : Polychoric correlation (using joint, two-step and polychoric series)
  module Bivariate
    autoload(:Polychoric, 'statsample/bivariate/polychoric')
    autoload(:Tetrachoric, 'statsample/bivariate/tetrachoric')
    class << self
      # Covariance between two vectors
      def covariance(v1,v2)
        v1a,v2a=Statsample.only_valid_clone(v1,v2)

        return nil if v1a.size==0
        if Statsample.has_gsl?
          GSL::Stats::covariance(v1a.to_gsl, v2a.to_gsl)
        else
          covariance_slow(v1a,v2a)
        end
      end
      # Estimate the ML between two dichotomic vectors
      def maximum_likehood_dichotomic(pred,real)
        preda,reala=Statsample.only_valid_clone(pred,real)                
        sum=0
        preda.each_index{|i|
           sum+=(reala[i]*Math::log(preda[i])) + ((1-reala[i])*Math::log(1-preda[i]))
        }
        sum
      end
      
      def covariance_slow(v1,v2) # :nodoc:
        v1a,v2a=Statsample.only_valid(v1,v2)
        sum_of_squares(v1a,v2a) / (v1a.size-1)
      end
      def sum_of_squares(v1,v2)
        v1a,v2a=Statsample.only_valid_clone(v1,v2)
        v1a.reset_index!
        v2a.reset_index!        
        m1=v1a.mean
        m2=v2a.mean
        (v1a.size).times.inject(0) {|ac,i| ac+(v1a[i]-m1)*(v2a[i]-m2)}
      end
      # Calculate Pearson correlation coefficient (r) between 2 vectors
      def pearson(v1,v2)
        v1a,v2a=Statsample.only_valid_clone(v1,v2)
        return nil if v1a.size ==0
        if Statsample.has_gsl?
          GSL::Stats::correlation(v1a.to_gsl, v2a.to_gsl)
        else
          pearson_slow(v1a,v2a)
        end
      end
      def pearson_slow(v1,v2) # :nodoc:
        v1a,v2a=Statsample.only_valid_clone(v1,v2)

        # Calculate sum of squares
        ss=sum_of_squares(v1a,v2a)
        ss.quo(Math::sqrt(v1a.sum_of_squares) * Math::sqrt(v2a.sum_of_squares))
      end
      alias :correlation :pearson
      # Retrieves the value for t test for a pearson correlation
      # between two vectors to test the null hipothesis of r=0
      def t_pearson(v1,v2)
        v1a,v2a=Statsample.only_valid_clone(v1,v2)
        r=pearson(v1a,v2a)
        if(r==1.0) 
          0
        else
          t_r(r,v1a.size)
        end
      end
      # Retrieves the value for t test for a pearson correlation
      # giving r and vector size
      # Source : http://faculty.chass.ncsu.edu/garson/PA765/correl.htm
      def t_r(r,size)
        r * Math::sqrt(((size)-2).to_f / (1 - r**2))
      end
      # Retrieves the probability value (a la SPSS)
      # for a given t, size and number of tails.
      # Uses a second parameter 
      # * :both  or 2  : for r!=0 (default)
      # * :right, :positive or 1  : for r > 0
      # * :left, :negative        : for r < 0
      
      def prop_pearson(t, size, tails=:both)
        tails=:both if tails==2
        tails=:right if tails==1 or tails==:positive
        tails=:left if tails==:negative
        
        n_tails=case tails
          when :both then 2
          else 1
        end
        t=-t if t>0 and (tails==:both)
        cdf=Distribution::T.cdf(t, size-2)
        if(tails==:right)
          1.0-(cdf*n_tails)
        else
          cdf*n_tails
        end
      end
      
      
      # Predicted time for pairwise correlation matrix, in miliseconds
      # See benchmarks/correlation_matrix.rb to see mode of calculation
      
      def prediction_pairwise(vars,cases)
        ((-0.518111-0.000746*cases+1.235608*vars+0.000740*cases*vars)**2) / 100
      end
      # Predicted time for optimized correlation matrix, in miliseconds
      # See benchmarks/correlation_matrix.rb to see mode of calculation
      
      def prediction_optimized(vars,cases)
        ((4+0.018128*cases+0.246871*vars+0.001169*vars*cases)**2) / 100
      end
      # Returns residual score after delete variance
      # from another variable
      # 
      def residuals(from,del)
        r=Statsample::Bivariate.pearson(from,del)
        froms, dels = from.vector_standarized, del.vector_standarized
        nv=[]
        froms.reset_index!
        dels.reset_index!
        froms.each_index do |i|
          if froms[i].nil? or dels[i].nil?
            nv.push(nil)
          else
            nv.push(froms[i]-r*dels[i])
          end
        end
        Daru::Vector.new(nv)
      end
      # Correlation between v1 and v2, controling the effect of
      # control on both.
      def partial_correlation(v1,v2,control)
        v1a,v2a,cona=Statsample.only_valid_clone(v1,v2,control)
        rv1v2=pearson(v1a,v2a)
        rv1con=pearson(v1a,cona)
        rv2con=pearson(v2a,cona)        
        (rv1v2-(rv1con*rv2con)).quo(Math::sqrt(1-rv1con**2) * Math::sqrt(1-rv2con**2))
      end
      
      def covariance_matrix_optimized(ds)
        x=ds.to_gsl
        n=x.row_size
        m=x.column_size
        means=((1/n.to_f)*GSL::Matrix.ones(1,n)*x).row(0)
        centered=x-(GSL::Matrix.ones(n,m)*GSL::Matrix.diag(means))
        ss=centered.transpose*centered
        s=((1/(n-1).to_f))*ss
        s
      end
      
      # Covariance matrix.
      # Order of rows and columns depends on Dataset#fields order
      
      def covariance_matrix(ds)
        vars,cases = ds.ncols, ds.nrows
        if !ds.has_missing_data? and Statsample.has_gsl? and prediction_optimized(vars,cases) < prediction_pairwise(vars,cases)
          cm=covariance_matrix_optimized(ds)
        else
          cm=covariance_matrix_pairwise(ds)
        end
        cm.extend(Statsample::CovariateMatrix)
        cm.fields = ds.vectors.to_a
        cm
      end
      
      
      def covariance_matrix_pairwise(ds)
        cache={}
        vectors = ds.vectors.to_a
        mat_rows = vectors.collect do |row|
          vectors.collect do |col|
            if (ds[row].type!=:numeric or ds[col].type!=:numeric)
              nil
            elsif row==col
              ds[row].variance
            else
              if cache[[col,row]].nil?
                cov=covariance(ds[row],ds[col])
                cache[[row,col]]=cov
                cov
              else
                cache[[col,row]]
              end
            end
          end
        end
        
        Matrix.rows mat_rows
      end
      
      # Correlation matrix.
      # Order of rows and columns depends on Dataset#fields order
      def correlation_matrix(ds)
        vars, cases = ds.ncols, ds.nrows
        if !ds.has_missing_data? and Statsample.has_gsl? and prediction_optimized(vars,cases) < prediction_pairwise(vars,cases)
          cm=correlation_matrix_optimized(ds)
        else
          cm=correlation_matrix_pairwise(ds)
        end
        cm.extend(Statsample::CovariateMatrix)
        cm.fields = ds.vectors.to_a
        cm
      end

      def correlation_matrix_optimized(ds)
        s=covariance_matrix_optimized(ds)
        sds=GSL::Matrix.diagonal(s.diagonal.sqrt.pow(-1))
        cm=sds*s*sds
        # Fix diagonal
        s.row_size.times {|i|
          cm[i,i]=1.0
        }
        cm
      end
      def correlation_matrix_pairwise(ds)
        cache={}
        vectors = ds.vectors.to_a
        cm = vectors.collect do |row|
          vectors.collect do |col|
            if row==col
              1.0
            elsif (ds[row].type!=:numeric or ds[col].type!=:numeric)
              nil
            else
              if cache[[col,row]].nil?
                r=pearson(ds[row],ds[col])
                cache[[row,col]]=r
                r
              else
                cache[[col,row]]
              end 
            end
          end
        end

        Matrix.rows cm
      end
      
      # Retrieves the n valid pairwise.
      def n_valid_matrix(ds)
        vectors = ds.vectors.to_a
        m = vectors.collect do |row|
          vectors.collect do |col|
            if row==col
              ds[row].only_valid.size
            else
              rowa,rowb = Statsample.only_valid_clone(ds[row],ds[col])
              rowa.size
            end
          end
        end

        Matrix.rows m
      end
      
      # Matrix of correlation probabilities.
      # Order of rows and columns depends on Dataset#fields order
      
      def correlation_probability_matrix(ds, tails=:both)
        rows=ds.fields.collect do |row|
          ds.fields.collect do |col|
            v1a,v2a=Statsample.only_valid_clone(ds[row],ds[col])
            (row==col or ds[row].type!=:numeric or ds[col].type!=:numeric) ? nil : prop_pearson(t_pearson(ds[row],ds[col]), v1a.size, tails)
          end
        end
        Matrix.rows(rows)
      end
      
      # Spearman ranked correlation coefficient (rho) between 2 vectors
      def spearman(v1,v2)
        v1a,v2a = Statsample.only_valid_clone(v1,v2)
        v1r,v2r = v1a.ranked, v2a.ranked
        pearson(v1r,v2r)
      end
      # Calculate Point biserial correlation. Equal to Pearson correlation, with
      # one dichotomous value replaced by "0" and the other by "1"
      def point_biserial(dichotomous,continous)
        ds = Daru::DataFrame.new({:d=>dichotomous,:c=>continous}).dup_only_valid
        raise(TypeError, "First vector should be dichotomous") if ds[:d].factors.size != 2
        raise(TypeError, "Second vector should be continous") if ds[:c].type != :numeric
        f0=ds[:d].factors.sort.to_a[0]
        m0=ds.filter_vector(:c) {|c| c[:d] == f0}
        m1=ds.filter_vector(:c) {|c| c[:d] != f0}
        ((m1.mean-m0.mean).to_f / ds[:c].sdp) * Math::sqrt(m0.size*m1.size.to_f / ds.nrows**2)
      end
      # Kendall Rank Correlation Coefficient (Tau a)
      # Based on Hervé Adbi article
      def tau_a(v1,v2)
        v1a,v2a=Statsample.only_valid_clone(v1,v2)
        n=v1.size
        v1r,v2r=v1a.ranked,v2a.ranked
        o1=ordered_pairs(v1r)
        o2=ordered_pairs(v2r)
        delta= o1.size*2-(o2  & o1).size*2
        1-(delta * 2 / (n*(n-1)).to_f)
      end
      # Calculates Goodman and Kruskal’s Tau b correlation.
      # Tb is an asymmetric P-R-E measure of association for nominal scales 
      # (Mielke, X)
      # 
      # Tau-b defines perfect association as strict monotonicity. Although it
      # requires strict monotonicity to reach 1.0, it does not penalize ties as
      # much as some other measures.
      # == Reference
      # Mielke, P. GOODMAN–KRUSKAL TAU AND GAMMA. 
      # Source: http://faculty.chass.ncsu.edu/garson/PA765/assocordinal.htm
      def tau_b(matrix)
        v=pairs(matrix)
        ((v['P']-v['Q']).to_f / Math::sqrt((v['P']+v['Q']+v['Y'])*(v['P']+v['Q']+v['X'])).to_f)
      end
      # Calculates Goodman and Kruskal's gamma.
      #
      # Gamma is the surplus of concordant pairs over discordant pairs, as a
      # percentage of all pairs ignoring ties.
      #
      # Source: http://faculty.chass.ncsu.edu/garson/PA765/assocordinal.htm
      def gamma(matrix)
        v=pairs(matrix)
        (v['P']-v['Q']).to_f / (v['P']+v['Q']).to_f
      end
      # Calculate indexes for a matrix the rows and cols has to be ordered
      def pairs(matrix)
        # calculate concordant #p matrix
        rs=matrix.row_size
        cs=matrix.column_size
        conc=disc=ties_x=ties_y=0
        (0...(rs-1)).each do |x|
          (0...(cs-1)).each do |y|
            ((x+1)...rs).each do |x2|
              ((y+1)...cs).each do |y2|
                # #p sprintf("%d:%d,%d:%d",x,y,x2,y2)
                conc+=matrix[x,y]*matrix[x2,y2]
              end
            end
          end
        end
        (0...(rs-1)).each {|x|
          (1...(cs)).each{|y|
            ((x+1)...rs).each{|x2|
              (0...y).each{|y2|
                # #p sprintf("%d:%d,%d:%d",x,y,x2,y2)
                disc+=matrix[x,y]*matrix[x2,y2]
              }
            }
          }
        }
        (0...(rs-1)).each {|x|
          (0...(cs)).each{|y|
            ((x+1)...(rs)).each{|x2|
              ties_x+=matrix[x,y]*matrix[x2,y]
            }
          }
        }
        (0...rs).each {|x|
          (0...(cs-1)).each{|y|
            ((y+1)...(cs)).each{|y2|
              ties_y+=matrix[x,y]*matrix[x,y2]
            }
          }
        }
        {'P'=>conc,'Q'=>disc,'Y'=>ties_y,'X'=>ties_x}
      end

      def ordered_pairs(vector)
        d = vector.to_a
        a = []
        (0...(d.size-1)).each do |i|
          ((i+1)...(d.size)).each do |j|
            a.push([d[i],d[j]])
          end
        end
        a
      end
=begin      
      def sum_of_codeviated(v1,v2)
        v1a,v2a=Statsample.only_valid(v1,v2)
        sum=0
        (0...v1a.size).each{|i|
          sum+=v1a[i]*v2a[i]
        }
        sum-((v1a.sum*v2a.sum) / v1a.size.to_f)
      end
=end
      # Report the minimum number of cases valid of a covariate matrix
      # based on a dataset
      def min_n_valid(ds)
        min = ds.nrows
        m   = n_valid_matrix(ds)
        for x in 0...m.row_size
          for y in 0...m.column_size
            min=m[x,y] if m[x,y] < min
          end
        end
        min
      end
    end
  end
end


