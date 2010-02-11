module Statsample
module Factor
  class PrincipalAxis
    MIN_CHANGE_ESTIMATE=0.0001
    include GetText
    bindtextdomain("statsample")
    attr_accessor :m, :name
    
    attr_reader :iterations, :initial_eigenvalues
    def initialize(matrix ,opts=Hash.new)
      @matrix=matrix
      @name=""
      @m=nil
      opts.each{|k,v|
        self.send("#{k}=",v) if self.respond_to? k
      }
      @clean=true
    end
    def communality(m)
      if m!=@m or @clean
        iterate(m)
        raise "Can't calculate comunnality" if @communality.nil?
      end
      @communality
    end
    def component_matrix(m)
      if m!=@m  or @clean
        iterate(m)
      end
      @component_matrix
    end

    def iterate(m, t=25)
      @clean=false
      @m=m
      work_matrix=@matrix.to_a
      prev_com=initial_communalities
      pca=PCA.new(::Matrix.rows(work_matrix))
      @initial_eigenvalues=pca.eigenvalues
      @iterations=0
      t.times do |i|
        @iterations+=1
        prev_com.each_with_index{|v,it|
          work_matrix[it][it]=v
        }
        pca=Statsample::PCA.new(::Matrix.rows(work_matrix))
        
        @communality=pca.communality(m)
        jump=true
        @communality.each_with_index do |v2,i2|
          raise "Variable #{i2} with communality > 1" if v2>1.0
          #p (v2-prev_com[i2]).abs
          jump=false if (v2-prev_com[i2]).abs>=MIN_CHANGE_ESTIMATE
        end
        break if jump
        prev_com=@communality
      end
      @component_matrix=pca.component_matrix(m)
    end
    
    
    def initial_communalities
      if @initial_communalities.nil?
        @initial_communalities=@matrix.column_size.times.collect {|i|
          rxx , rxy = FactorialAnalysis.separate_matrices(@matrix,i)
          matrix=(rxy.t*rxx.inverse*rxy)
          matrix[0,0]
        }
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
    
    
    def to_reportbuilder(generator)
      anchor=generator.add_toc_entry(_("Factor Analysis: ")+name)
      generator.add_html "<div class='pca'>"+_("Factor Analysis")+" #{@name}<a name='#{anchor}'></a>"
      if @m.nil?
        # Set number of factors with eigenvalues > 1
        m=@eigenpairs.find_all {|v| v[0]>=1.0}.size
      else
        m=@m
      end
      generator.add_text "Number of factors: #{m}"
      t=ReportBuilder::Table.new(:name=>_("Communalities"), :header=>["Variable","Initial","Extraction"])
      communality(m).each_with_index {|com,i|
        t.add_row([i, sprintf("%0.3f", initial_communalities[i]), sprintf("%0.3f", com)])
      }
      generator.parse_element(t)
      
      t=ReportBuilder::Table.new(:name=>_("Eigenvalues"), :header=>["Variable","Value"])
      @initial_eigenvalues.each_with_index {|eigenvalue,i|
        t.add_row([i, sprintf("%0.3f",eigenvalue)])
      }
      generator.parse_element(t)
      
      t=ReportBuilder::Table.new(:name=>_("Component Matrix"), :header=>["Variable"]+m.times.collect {|c| c+1})
      
      i=0
      component_matrix(m).to_a.each do |row|
        t.add_row([i]+row.collect {|c| sprintf("%0.3f",c)})
        i+=1
      end
      generator.parse_element(t)
      generator.add_html("</div>")
    end
    
    
  end
  
end
end
