require 'statsample/regression/multiple/baseengine'
module Statsample
  module Regression
    # Module for OLS Multiple Regression Analysis.
    # 
    #  Use:.
    #
    #  require 'statsample'
    #  a = Daru::Vector.new(1000.times.collect {rand})
    #  b = Daru::Vector.new(1000.times.collect {rand})
    #  c = Daru::Vector.new(1000.times.collect {rand})
    #  ds= Daru::DataFrame.new({:a => a,:b => b,:c => c})
    #  ds[:y]=ds.collect{|row| row[:a]*5 + row[:b]*3 + row[:c]*2 + rand()}
    #  lr=Statsample::Regression.multiple(ds, :y)
    #  puts lr.summary
    #  Summary for regression of a,b,c over y
    #  *************************************************************
    #  Engine: Statsample::Regression::Multiple::AlglibEngine
    #  Cases(listwise)=1000(1000)
    #  r=0.986
    #  r2=0.973
    #  Equation=0.504+5.011a + 2.995b + 1.988c
    #  ----------------------------
    #  ANOVA TABLE
    #  --------------------------------------------------------------
    #  |  source     | ss       | df  | ms      | f         | s     |
    #  --------------------------------------------------------------
    #  |  Regression | 2979.321 | 3   | 993.107 | 12040.067 | 0.000 |
    #  |  Error      | 82.154   | 996 | 0.082   |           |       |
    #  |  Total      | 3061.475 | 999 |         |           |       |
    #  --------------------------------------------------------------
    #  Beta coefficientes
    #  -----------------------------------------------
    #  |  coeff    | b     | beta  | se    | t       |
    #  -----------------------------------------------
    #  |  Constant | 0.504 | -     | 0.030 | 16.968  |
    #  |  a        | 5.011 | 0.832 | 0.031 | 159.486 |
    #  |  b        | 2.995 | 0.492 | 0.032 | 94.367  |
    #  |  c        | 1.988 | 0.323 | 0.032 | 62.132  |
    #  -----------------------------------------------
    # 
    module Multiple
      # Obtain r2 for regressors
      def self.r2_from_matrices(rxx,rxy)
        matrix=(rxy.transpose*rxx.inverse*rxy)
        matrix[0,0]
      end
      
      class MultipleDependent
        def significance
          0.0
        end
        def initialize(matrix,y_var, opts=Hash.new)
          matrix.extend Statsample::CovariateMatrix
          @matrix=matrix
          @fields=matrix.fields - y_var
          @y_var = y_var
          @q=@y_var.size
          @matrix_cor=matrix.correlation
          @matrix_cor_xx = @matrix_cor.submatrix(@fields)
          @matrix_cor_yy = @matrix_cor.submatrix(y_var, y_var)
          
          @sxx = @matrix.submatrix(@fields)
          @syy = @matrix.submatrix(y_var, y_var)
          @sxy = @matrix.submatrix(@fields, y_var)
          @syx = @sxy.t
        end
        
        def r2yx
          1- (@matrix_cor.determinant.quo(@matrix_cor_yy.determinant * @matrix_cor_xx.determinant))
        end
        # Residual covariance of Y after accountin with lineal relation with x
        def syyx
          @syy-@syx*@sxx.inverse*@sxy
        end
        def r2yx_covariance
          1-(syyx.determinant.quo(@syy.determinant))
        end
        
        def vxy
          @q-(@syy.inverse*syyx).trace
        end
        def p2yx
          vxy.quo(@q)
        end
      end
    end
  end
end
