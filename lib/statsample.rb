# = statsample.rb - 
# Statsample - Statistic package for Ruby
# Copyright (C) 2008-2009  Claudio Bustos
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#


#$:.unshift(File.dirname(__FILE__))
require 'matrix'
require 'distribution'
require 'dirty-memoize'
gem 'reportbuilder','~>1.0'
require 'reportbuilder'
class Numeric
  def square ; self * self ; end
end

class String
  def is_number?
    if self =~ /^-?\d+[,.]?\d*(e-?\d+)?$/
        true
    else
        false
    end
  end
end


class Array
  # Recode repeated values on an array, adding the number of repetition
  # at the end
  # Example:
  #   a=%w{a b c c d d d e}
  #   a.recode_repeated
  #   => ["a","b","c_1","c_2","d_1","d_2","d_3","e"]
  def recode_repeated
    if self.size!=self.uniq.size
      # Find repeated
      repeated=self.inject({}) {|a,v|
      (a[v].nil? ? a[v]=1 : a[v]+=1); a }.find_all{|k,v| v>1}.collect{|k,v| k}
      ns=repeated.inject({}) {|a,v| a[v]=0;a}
      self.collect do |f|
        if repeated.include? f
          ns[f]+=1
          sprintf("%s_%d",f,ns[f])
        else
          f
        end
      end
    else
      self
    end
  end
end

def create_test(*args,&proc) 
  description=args.shift
  fields=args
  [description, fields, Proc.new]
end
#--
# Test extensions
begin
  require 'gettext'
rescue LoadError
  def bindtextdomain(d) #:nodoc:
  d
  end
  
  # Bored module
  module GetText  #:nodoc:
    def _(t)  
        t
    end
  end
end
# Library for statistical analysis on Ruby
#
# * Classes for manipulation and storage of data:
# * Module Statsample::Bivariate provides covariance and pearson, spearman, point biserial, tau a, tau b, gamma, tetrachoric (see Bivariate::Tetrachoric) and polychoric (see Bivariate::Polychoric) correlations. Include methods to create correlation and covariance matrices
# * Multiple types of regression on Statsample::Regression
# * Factorial Analysis algorithms on Statsample::Factor module.
# * Dominance Analysis. Based on Budescu and Azen papers.link[http://psycnet.apa.org/journals/met/8/2/129/]. 
# * Module Statsample::Codification, to help to codify open questions
# * Converters to import and export data from databases, csv and excel files.
# * Module Statsample::Crosstab provides function to create crosstab for categorical data
# * Reliability analysis provides functions to analyze scales.
# * Module Statsample::SRS (Simple Random Sampling) provides a lot of functions to estimate standard error for several type of samples
# * Interfaces to gdchart, gnuplot and SVG::Graph 
#
module Statsample
  begin
    require 'rbgsl'
    def self.has_gsl?
      true
    end
  rescue LoadError
    def self.has_gsl?
      false
    end
  end
  VERSION = '0.10.0'
  SPLIT_TOKEN = ","
  autoload(:Database, 'statsample/converters')
  autoload(:Anova, 'statsample/anova')
  autoload(:Combination, 'statsample/combination')
  autoload(:Permutation, 'statsample/permutation')
  autoload(:CSV, 'statsample/converters')
  autoload(:PlainText, 'statsample/converters')
  autoload(:Excel, 'statsample/converters')
  autoload(:GGobi, 'statsample/converters')
  autoload(:SPSS, 'statsample/converter/spss')
  autoload(:Histogram, 'statsample/histogram')
  autoload(:DominanceAnalysis, 'statsample/dominanceanalysis')
  autoload(:HtmlReport, 'statsample/htmlreport')
  autoload(:Mx, 'statsample/converters')
  autoload(:Resample, 'statsample/resample')
  autoload(:SRS, 'statsample/srs')
  autoload(:Codification, 'statsample/codification')
  autoload(:Reliability, 'statsample/reliability')
  autoload(:Bivariate, 'statsample/bivariate')
  autoload(:Multivariate, 'statsample/multivariate')
  autoload(:Multiset, 'statsample/multiset')
  autoload(:StratifiedSample, 'statsample/multiset')
  autoload(:MLE, 'statsample/mle')    
  autoload(:Regression, 'statsample/regression')
  autoload(:Test, 'statsample/test')
  autoload(:Factor, 'statsample/factor')
  autoload(:Graph, 'statsample/graph')
  
  
  class << self
    # Load a object saved on a file.
    def load(filename)
      if File.exists? filename
        o=false
        File.open(filename,"r") {|fp| o=Marshal.load(fp) }
        o
      else
        false
      end
    end
    
    # Create a matrix using vectors as columns.
    # Use:
    #
    #   matrix=Statsample.vector_cols_matrix(v1,v2)
    def vector_cols_matrix(*vs)
      # test
      size=vs[0].size
      vs.each{|v|
        raise ArgumentError,"Arguments should be Vector" unless v.instance_of? Statsample::Vector
        raise ArgumentError,"Vectors size should be the same" if v.size!=size
      }
      Matrix.rows((0...size).to_a.collect() {|i|
        vs.collect{|v| v[i]}
      })
    end
    # Returns a duplicate of the input vectors, without missing data
    # for any of the vectors.
    # 
    #  a=[1,2,3,6,7,nil,3,5].to_scale
    #  b=[nil,nil,5,6,4,5,10,2].to_scale
    #  c=[2,4,6,7,4,5,6,7].to_scale
    #  a2,b2,c2=Statsample.only_valid(a,b,c)
    #  => [#<Statsample::Scale:0xb748c8c8 @data=[3, 6, 7, 3, 5]>, 
    #        #<Statsample::Scale:0xb748c814 @data=[5, 6, 4, 10, 2]>, 
    #        #<Statsample::Scale:0xb748c760 @data=[6, 7, 4, 6, 7]>]
    #
    def only_valid(*vs)
      i=1
      h=vs.inject({}) {|a,v| a["v#{i}"]=v;i+=1;a}
      ds=Statsample::Dataset.new(h).dup_only_valid
      ds.vectors.values
    end
    # Cheap version of #only_valid. 
    # If any vectors have missing_values, return only valid.
    # If not, return the vectors it self
    def only_valid_clone(*vs)
      if vs.any? {|v| v.has_missing_data?}
        only_valid(*vs)
      else
        vs
      end
    end
  end  
  
  
  
  
	module Util
    # Reference: http://www.itl.nist.gov/div898/handbook/eda/section3/normprpl.htm
    def normal_order_statistic_medians(i,n)
      if i==1
          u= 1.0 - normal_order_statistic_medians(n,n)
      elsif i==n
          u=0.5**(1 / n.to_f)
      else
          u= (i - 0.3175) / (n + 0.365)
      end
      u
    end
	end
  
  
  
  module Writable
    def save(filename)
      fp=File.open(filename,"w")
      Marshal.dump(self,fp)
      fp.close
    end        
  end
  # Provides basic method to generate summaries
  module Summarizable
    include GetText
    bindtextdomain("statsample")
    def summary(method=:to_text)
      ReportBuilder.new(:no_title=>true).add(self).send(method)
    end
  end
  module STATSAMPLE__ #:nodoc:
  end
end



#--
begin 
  require 'statsamplert'
rescue LoadError
  module Statsample 
      OPTIMIZED=false
  end
end

require 'statsample/vector'
require 'statsample/dataset'
require 'statsample/crosstab'
require 'statsample/matrix'
