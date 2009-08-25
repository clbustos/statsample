# multivariate normal model.
# From 
# Peter von Tessin:  Maximum Likelihood with Java and Ruby (first draft)  pdf 
# http://petertessin.com/
#
class Normal
    def first_derivative(x,y,p)
    n = x.row_size
    k = x.column_size
    b = Array.new(k)
    k.times{|i| b[i]=[p[i,0]]}
    beta = Matrix.rows(b)
    sigma2 = p[k,0]
    sigma4=sigma2*sigma2
    e = y-(x*(beta))
    xte = x.transpose*(e)
    ete = e.transpose*(e)
    #rows of the Jacobian
    rows = Array.new(k+1)
    k.times{|i| rows[i] = [xte[i,0] / sigma2]}
    rows[k] = [ete[0,0] / (2*sigma4) - n/(2*sigma2)]
    fd = Matrix.rows(rows, true)
    end
    
    def second_derivative(x,y,p)
    n = x.row_size
    k = x.column_size
    b = Array.new(k)
    k.times{|i| b[i]=[p[i,0]]}
    beta = Matrix.rows(b)
    sigma2 = p[k,0]
    sigma4=sigma2*sigma2
    sigma6 = sigma2*sigma2*sigma2
    e = y-(x*(beta))
    xtx = x.transpose*(x)
    xte = x.transpose*(e)
    ete = e.transpose*(e)
    #rows of the Hessian
    rows = Array.new(k+1)
    k.times do |i|
        row = Array.new(k+1)
        k.times do |j|
            row[j] = -xtx[i,j] / sigma2
        end
        row[k] = -xte[i,0] / sigma4
        rows[i] = row
    end
    last_row = Array.new(k+1)
    k.times do |i|
        last_row[i] = -xte[i,0] / sigma4
    end
    last_row[k] = 2*sigma4 - ete[0,0] / sigma6
    rows[k] = last_row
    sd = Matrix.rows(rows, true)
    end
end
