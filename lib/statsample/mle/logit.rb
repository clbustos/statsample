module Statsample
  module MLE
    # Logit MLE estimation. 
    # See Statsample::Regression for methods to generate a logit regression.
    # Usage:
    # 
    #   mle=Statsample::MLE::Logit.new
    #   mle.newton_raphson(x,y)
    #   beta=mle.parameters
    #   likehood=mle.likehood(x, y, beta)
    #   iterations=mle.iterations
    #         
    class Logit < BaseMLE
    # F(B'Xi)
    def f(b,xi)
      p_bx=(xi*b)[0,0] 
      res=(1.0/(1.0+Math::exp(-p_bx)))
      if res==0.0
          res=1e-15
      elsif res==1.0
          res=0.999999999999999
      end
      res
    end
    # Likehood for x_i vector, y_i scalar and b parameters
    def likehood_i(xi,yi,b)
      (f(b,xi)**yi)*((1-f(b,xi))**(1-yi))
    end
    # Log Likehood for x_i vector, y_i scalar and b parameters
    def log_likehood_i(xi,yi,b)
      fbx=f(b,xi)
      (yi.to_f*Math::log(fbx))+((1.0-yi.to_f)*Math::log(1.0-fbx))
    end
    
    # First derivative of log-likehood function
    # x: Matrix (NxM)
    # y: Matrix (Nx1)
    # p: Matrix (Mx1)
    def first_derivative(x,y,p)
      raise "x.rows!=y.rows" if x.row_size!=y.row_size
      raise "x.columns!=p.rows" if x.column_size!=p.row_size            
      n = x.row_size
      k = x.column_size
      fd = Array.new(k)
      k.times {|i| fd[i] = [0.0]}
      n.times do |i|
        row = x.row(i).to_a
        value1 = (1-y[i,0]) -p_plus(row,p)
      k.times do |j|
        fd[j][0] -= value1*row[j]
        end
      end
      Matrix.rows(fd, true)
    
    end
    # Second derivative of log-likehood function
    # x: Matrix (NxM)
    # y: Matrix (Nx1)
    # p: Matrix (Mx1)
    def second_derivative(x,y,p)
      raise "x.rows!=y.rows" if x.row_size!=y.row_size
      raise "x.columns!=p.rows" if x.column_size!=p.row_size             
      n = x.row_size
      k = x.column_size
      sd = Array.new(k)
      k.times do |i|
        arr = Array.new(k)
        k.times{ |j| arr[j]=0.0}
        sd[i] = arr
      end
      n.times do |i|
        row = x.row(i).to_a
        p_m = p_minus(row,p)
        k.times do |j|
          k.times do |l|
          sd[j][l] -= p_m *(1-p_m)*row[j]*row[l]
          end
        end
      end
      Matrix.rows(sd, true)
    end
    private
    def p_minus(x_row,p)
      value = 0.0;
      x_row.each_index { |i| value += x_row[i]*p[i,0]}
      1/(1+Math.exp(-value))
    end
    def p_plus(x_row,p)
      value = 0.0;
      x_row.each_index { |i| value += x_row[i]*p[i,0]}
      1/(1+Math.exp(value))
    end
    
    end # Logit
  end # MLE
end # Statsample
