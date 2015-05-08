module Statsample
  module Factor
  # = Velicer's Minimum Average Partial
  # 
  # "Velicer’s (1976) MAP test involves a complete princi-
  # pal components analysis followed by the examination of
  # a series of matrices of partial correlations. Specifically,
  # on the first step, the first principal component is par-
  # tialed out of the correlations between the variables of in-
  # terest, and the average squared coefficient in the off-
  # diagonals of the resulting partial correlation matrix is
  # computed. On the second step, the first two principal
  # components are partialed out of the original correlation
  # matrix and the average squared partial correlation is
  # again computed. These computations are conducted for k
  # (the number of variables) minus one steps. The average
  # squared partial correlations from these steps are then
  # lined up, and the number of components is determined by
  # the step number in the analyses that resulted in the lowest
  # average squared partial correlation. The average squared
  # coefficient in the original correlation matrix is also com-
  # puted, and if this coefficient happens to be lower than
  # the lowest average squared partial correlation, then no
  # components should be extracted from the correlation ma-
  # trix. Statistically, components are retained as long as the
  # variance in the correlation matrix represents systematic
  # variance. Components are no longer retained when there
  # is proportionately more unsystematic variance than sys-
  # tematic variance." (O'Connor, 2000, p.397).
  # 
  # Current algorithm is loosely based on SPSS O'Connor algorithm
  # 
  # == Reference
  # * O'Connor, B. (2000). SPSS and SAS programs for determining the number of components using parallel analysis and Velicer's MAP test. Behavior Research Methods, Instruments, & Computers, 32(3), 396-402.
  #



    class MAP
      include Summarizable
      include DirtyMemoize
      # Name of analysis
      attr_accessor :name
      attr_reader :eigenvalues
      # Number of factors to retain
      attr_reader :number_of_factors
      # Average squared correlations
      attr_reader :fm
      # Smallest average squared correlation
      attr_reader :minfm
      
      attr_accessor :use_gsl
      def self.with_dataset(ds,opts=Hash.new)
        new(ds.correlation_matrix,opts)
      end
      def initialize(matrix, opts=Hash.new)
        @matrix=matrix
        opts_default={
          :use_gsl=>true,
          :name=>_("Velicer's MAP")
        }
        @opts=opts_default.merge(opts)
         opts_default.keys.each {|k| send("#{k}=", @opts[k]) }
      end
      def compute
        gsl_m=(use_gsl and Statsample.has_gsl?) ? @matrix.to_gsl : @matrix
        klass_m=gsl_m.class
        eigvect,@eigenvalues=gsl_m.eigenvectors_matrix, gsl_m.eigenvalues
        eigenvalues_sqrt=@eigenvalues.collect {|v| Math.sqrt(v)}
        loadings=eigvect*(klass_m.diagonal(*eigenvalues_sqrt))
        fm=Array.new(@matrix.row_size)
        ncol=@matrix.column_size
        
        fm[0]=(gsl_m.mssq - ncol).quo(ncol*(ncol-1))
        
        (ncol-1).times do |m|
          puts "MAP:Eigenvalue #{m+1}" if $DEBUG
          a=use_gsl ? loadings[0..(loadings.row_size-1),0..m] : 
            loadings.minor(0..(loadings.row_size-1),0..m)
          partcov= gsl_m - (a*a.transpose)
          
          d=klass_m.diagonal(*(partcov.diagonal.collect {|v| Math::sqrt(1/v)}))
          pr=d*partcov*d
          fm[m+1]=(pr.mssq-ncol).quo(ncol*(ncol-1))
        end
        minfm=fm[0]
        nfactors=0
        @errors=[]
        fm.each_with_index do |v,s|
          if defined?(Complex) and v.is_a? ::Complex
            @errors.push(s)
          else
            if v < minfm
              minfm=v
              nfactors=s
            end
          end
        end
        @number_of_factors=nfactors
        @fm=fm
        @minfm=minfm
        
      end
      def report_building(g) #:nodoc:
        g.section(:name=>@name) do |s|
          s.table(:name=>_("Eigenvalues"),:header=>[_("Value")]) do |t|
            eigenvalues.each_with_index do |e,i|
                t.row([@errors.include?(i) ? "*" : "%0.6f" % e])
            end
          end
          s.table(:name=>_("Velicer's Average Squared Correlations"), :header=>[_("number of components"),_("average square correlation")]) do |t|
            fm.each_with_index do |v,i|
              t.row(["%d" % i, @errors.include?(i) ? "*" : "%0.6f" % v])
            end
          end
          s.text(_("The smallest average squared correlation is : %0.6f" % minfm))
          s.text(_("The number of components is : %d" % number_of_factors))
        end
      end
      dirty_memoize :number_of_factors, :fm, :minfm, :eigenvalues

    end
  end
end
