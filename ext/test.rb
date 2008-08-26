require 'rubyss_ext'
require '../lib/rubyss'
require 'rubyss/chidistribution'

b=0.2
k=2

p RubySS.chi_square_p(b,k,1)
p RubySS.chi_square_x(0.095,k,1)

