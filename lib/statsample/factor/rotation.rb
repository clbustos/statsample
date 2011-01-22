module Statsample
module Factor
  # Base class for component matrix rotation.
  #
  # == Reference:
  # * SPSS Manual
  # * Lin, J. (2007). VARIMAX_K58 [Source code]. [http://www.johnny-lin.com/idl_code/varimax_k58.pro]
  # 
  # Use subclasses Varimax, Equimax or Quartimax for desired type of rotation
  #   Use:
  #   a = Matrix[ [ 0.4320,  0.8129,  0.3872] 
  #     , [ 0.7950, -0.5416,  0.2565]  
  #     , [ 0.5944,  0.7234, -0.3441]  
  #     , [ 0.8945, -0.3921, -0.1863] ]
  #   rotation = Statsample::Factor::Varimax(a)
  #   rotation.iterate
  #   p rotation.rotated
  #   p rotation.component_transformation_matrix
  # 
  class Rotation
    EPSILON=1e-15
    MAX_ITERATIONS=25
    include Summarizable
    include DirtyMemoize
    attr_reader :iterations, :rotated, :component_transformation_matrix, :h2
    # Maximum number of iterations    
    attr_accessor :max_iterations
    # Maximum precision    
    attr_accessor :epsilon
    attr_accessor :use_gsl
    dirty_writer :max_iterations, :epsilon
    dirty_memoize :iterations, :rotated, :component_transformation_matrix, :h2
    
    def initialize(matrix, opts=Hash.new)
      @name=_("%s rotation") % rotation_name
      @matrix=matrix
      @n=@matrix.row_size # Variables, p on original
      @m=@matrix.column_size # Factors, r on original
      @component_transformation_matrix=nil
      @max_iterations=MAX_ITERATIONS
      @epsilon=EPSILON
      @rotated=nil
      @h2=(@matrix.collect {|c| c**2} * Matrix.column_vector([1]*@m)).column(0).to_a
      @use_gsl=Statsample.has_gsl?
      opts.each{|k,v|
        self.send("#{k}=",v) if self.respond_to? k
      }
    end
    def report_building(g)
      g.section(:name=>@name) do |s|
        s.parse_element(rotated)
        s.parse_element(component_transformation_matrix)
      end
    end
    alias_method :communalities, :h2
    alias_method :rotated_component_matrix, :rotated
    def compute
      iterate
    end
    # Start iteration 
    def iterate
      k_matrix=@use_gsl ? GSL::Matrix : ::Matrix
      t=k_matrix.identity(@m)
      b=(@use_gsl ? @matrix.to_gsl : @matrix.dup)
      h=k_matrix.diagonal(*@h2).collect {|c| Math::sqrt(c)}
      h_inverse=h.collect {|c| c!=0 ? 1/c : 0 }
      bh=h_inverse * b
      @not_converged=true
      @iterations=0
      while @not_converged
        break if @iterations>@max_iterations
        @iterations+=1
        #puts "Iteration #{iterations}"
        num_pairs=@m*(@m-1).quo(2)
        (0..(@m-2)).each do |i| #+ go through factor index 0:r-1-1 (begin)
          ((i+1)..(@m-1)).each do |j| #+ pair i to "rest" of factors (begin)
            
            xx = bh.column(i)
            yy = bh.column(j)
            tx = t.column(i)
            ty = t.column(j)
            
            uu = @n.times.collect {|var_i| xx[var_i]**2-yy[var_i]**2}
            vv = @n.times.collect {|var_i| 2*xx[var_i]*yy[var_i]}
            
            a  = @n.times.inject(0) {|ac,var_i| ac+ uu[var_i] }
            b  = @n.times.inject(0) {|ac,var_i| ac+ vv[var_i] }
            c  = @n.times.inject(0) {|ac,var_i| ac+ (uu[var_i]**2 - vv[var_i]**2) }
            d  = @n.times.inject(0) {|ac,var_i| ac+ (2*uu[var_i]*vv[var_i]) }
            num=x(a,b,c,d)
            den=y(a,b,c,d)
            phi=Math::atan2(num,den) / 4.0
            # puts "#{i}-#{j}: #{phi}"
            
            if(Math::sin(phi.abs) >= @epsilon)
              xx_rot=( Math::cos(phi)*xx)+(Math::sin(phi)*yy)
              yy_rot=((-Math::sin(phi))*xx)+(Math::cos(phi)*yy)
              
              
              tx_rot=( Math::cos(phi)*tx)+(Math::sin(phi)*ty)
              ty_rot=((-Math::sin(phi))*tx)+(Math::cos(phi)*ty)

              
              bh=bh.to_a

              @n.times {|row_i|
                bh[row_i][i] = xx_rot[row_i]
                bh[row_i][j] = yy_rot[row_i]
              }
              t=t.to_a
              @m.times {|row_i|
                t[row_i][i]=tx_rot[row_i]
                t[row_i][j]=ty_rot[row_i]
              }
              #if @use_gsl
                bh=k_matrix.[](*bh)
                t=k_matrix.[](*t)
              #else
              #  bh=Matrix.rows(bh)
              #  t=Matrix.rows(t)
                
              #end
            else
              num_pairs=num_pairs-1
              @not_converged=false if num_pairs==0
            end # if
          end #j
        end #i
      end # while
      @rotated=h*bh
      @rotated.extend CovariateMatrix
      @rotated.name=_("Rotated Component matrix")
      
      if @matrix.respond_to? :fields_x
        @rotated.fields_x = @matrix.fields_x
      else
        @rotated.fields_x = @n.times.map {|i| "var_#{i+1}"}
      end
      if @matrix.respond_to? :fields_y
        @rotated.fields_y = @matrix.fields_y
      else
        @rotated.fields_y = @m.times.map {|i| "var_#{i+1}"}
      end
      
      
      
      @component_transformation_matrix=t
      @component_transformation_matrix.extend CovariateMatrix
      @component_transformation_matrix.name=_("Component transformation matrix")
      
      if @matrix.respond_to? :fields_y
        @component_transformation_matrix.fields = @matrix.fields_y
        
      else
        @component_transformation_matrix.fields = @m.times.map {|i| "var_#{i+1}"}
      end
      
      @rotated
    end

  end
  class Varimax < Rotation
    def x(a,b,c,d)
      d-(2*a*b / @n.to_f)
    end
    def y(a,b,c,d)
      c-((a**2-b**2) / @n.to_f)
    end
    def rotation_name
      "Varimax"
    end
  end
  class Equimax < Rotation
    def x(a,b,c,d)
      d-(@m*a*b / @n.to_f)
    end
    def y(a,b,c,d)
      c-@m*((a**2-b**2) / (2*@n.to_f))
    end
    def rotation_name
      "Equimax"
    end

  end
  class Quartimax < Rotation
    def x(a,b,c,d)
      d
    end
    def y(a,b,c,d)
      c
    end
    def rotation_name
      "Quartimax"
    end
    
  end
end
end
