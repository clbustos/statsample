module Statsample
module Factor
  # Principal Axis Analysis for a covariance or correlation matrix. 
  #
  # For PCA, use Statsample::Factor::PCA
  # 
  # == Usage:
  #   require 'statsample'
  #   a=[2.5, 0.5, 2.2, 1.9, 3.1, 2.3, 2.0, 1.0, 1.5, 1.1].to_scale
  #   b=[2.4,0.7,2.9,2.2,3.0,2.7,1.6,1.1,1.6,0.9].to_scale
  #   ds={'a'=>a,'b'=>b}.to_dataset
  #   cor_matrix=Statsample::Bivariate.correlation_matrix(ds)
  #   pa=Statsample::Factor::PrincipalAxis.new(cor_matrix)
  #   pa.iterate(1)
  #   pa.m
  #   => 1
  #   pca.component_matrix
  #   => GSL::Matrix
  #   [  9.622e-01 
  #      9.622e-01 ]
  #   pca.communalities
  #   => [0.962964636346122, 0.962964636346122]
  #
  # == References:
  #
  # * SPSS manual
  # * Smith, L. (2002). A tutorial on Principal Component Analysis. Available on http://courses.eas.ualberta.ca/eas570/pca_tutorial.pdf 
  #   
  class PrincipalAxis
    include DirtyMemoize
    # Minimum difference between succesive iterations on sum of communalities
    DELTA=1e-3
    # Maximum number of iterations
    MAX_ITERATIONS=50
    include GetText
    bindtextdomain("statsample")
    # Number of factors. Set by default to the number of factors
    # with eigen values > 1 on PCA over data
    attr_accessor :m
    
    # Name of analysis
    attr_accessor :name
    
    # Number of iterations required to converge
    attr_reader :iterations
    # Initial eigenvalues 
    attr_reader :initial_eigenvalues
    # Tolerance for iteratios.
    attr_accessor :epsilon
    # Use SMC(squared multiple correlations) as diagonal. If false, use 1
    attr_accessor :smc
    # Maximum number of iterations
    attr_accessor :max_iterations
    # Eigenvalues of factor analysis
    attr_reader :eigenvalues
    
    
    
    def initialize(matrix, opts=Hash.new)
      @matrix=matrix
      @name=""
      @m=nil
      @initial_eigenvalues=nil
      @initial_communalities=nil
      @component_matrix=nil
      @delta=DELTA
      @smc=true
      @max_iterations=MAX_ITERATIONS
      opts.each{|k,v|
        self.send("#{k}=",v) if self.respond_to? k
      }
      
      if @m.nil?
        pca=PCA.new(::Matrix.rows(@matrix.to_a))
        @m=pca.m
      end
      
      @clean=true
    end
    # Communality for all variables given m factors
    def communalities(m=nil)
      if m!=@m or @clean
        iterate(m)
        raise "Can't calculate comunality" if @communalities.nil?
      end
      @communalities
    end
    # Component matrix for m factors
    def component_matrix(m=nil)
      if m!=@m  or @clean
        iterate(m)
      end
      @component_matrix
    end
    # Iterate to find the factors
    def iterate(m=nil)
      @clean=false
      m||=@m
      @m=m
      t = @max_iterations
      work_matrix=@matrix.to_a
      
      prev_com=initial_communalities
      
      pca=PCA.new(::Matrix.rows(work_matrix))
      @initial_eigenvalues=pca.eigenvalues
      prev_sum=prev_com.inject(0) {|ac,v| ac+v}
      @iterations=0
      t.times do |i|
        @iterations+=1
        prev_com.each_with_index{|v,it|
          work_matrix[it][it]=v
        }
        pca=PCA.new(::Matrix.rows(work_matrix))
        @communalities=pca.communalities(m)
        @eigenvalues=pca.eigenvalues
        com_sum=@communalities.inject(0) {|ac,v| ac+v}
        jump=true
        
        break if (com_sum-prev_sum).abs<@delta
        @communalities.each_with_index do |v2,i2|
          raise "Variable #{i2} with communality > 1" if v2>1.0
        end
        prev_sum=com_sum
        prev_com=@communalities
        
      end
      @component_matrix=pca.component_matrix(m)
    end
    alias :compute :iterate 
    
    def initial_communalities
      if @initial_communalities.nil?
        if @smc
        @initial_communalities=@matrix.column_size.times.collect {|i|
          rxx , rxy = PrincipalAxis.separate_matrices(@matrix,i)
          matrix=(rxy.t*rxx.inverse*rxy)
          matrix[0,0]
        }
        else
          @initial_communalities=[1.0]*@matrix.column_size
        end
      end      
      @initial_communalities
    end
    
    
    # Returns two matrixes from a correlation matrix
    # with regressors correlation matrix and criteria xy
    # matrix.
    def self.separate_matrices(matrix, y)
      ac=[]
      matrix.column_size.times do |i|
        ac.push(matrix[y,i]) if i!=y
      end
      rxy=Matrix.columns([ac])
      rows=[]
      matrix.row_size.times do |i|
        if i!=y
          row=[]
          matrix.row_size.times do |j|
            row.push(matrix[i,j]) if j!=y
          end
          rows.push(row)
        end
      end
      rxx=Matrix.rows(rows)
      [rxx,rxy]
    end
    def summary
      rp=ReportBuilder.new()
      rp.add(self)
      rp.to_text
    end
    def report_building(generator)
      iterate if @clean
      anchor=generator.toc_entry(_("Factor Analysis: ")+name)
      generator.html "<div class='pca'>"+_("Factor Analysis")+" #{@name}<a name='#{anchor}'></a>"
     
      generator.text "Number of factors: #{m}"
      generator.text "Iterations: #{@iterations}"
      
      t=ReportBuilder::Table.new(:name=>_("Communalities"), :header=>["Variable","Initial","Extraction"])
      communalities(m).each_with_index {|com,i|
        t.row([i, sprintf("%0.4f", initial_communalities[i]), sprintf("%0.3f", com)])
      }
      generator.parse_element(t)
      
      t=ReportBuilder::Table.new(:name=>_("Eigenvalues"), :header=>["Variable","Value"])
      @initial_eigenvalues.each_with_index {|eigenvalue,i|
        t.row([i, sprintf("%0.3f",eigenvalue)])
      }
      generator.parse_element(t)
      
      t=ReportBuilder::Table.new(:name=>_("Component Matrix"), :header=>["Variable"]+m.times.collect {|c| c+1})
      
      i=0
      component_matrix(m).to_a.each do |row|
        t.row([i]+row.collect {|c| sprintf("%0.3f",c)})
        i+=1
      end
      generator.parse_element(t)
      generator.html("</div>")
    end
    
    dirty_writer :max_iterations, :epsilon, :smc
    dirty_memoize :eigenvalues, :iterations, :initial_eigenvalues

  end
  
end
end
