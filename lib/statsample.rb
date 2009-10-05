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


$:.unshift(File.dirname(__FILE__))
$:.unshift(File.expand_path(File.dirname(__FILE__)+"/../ext"))

require 'matrix'
require 'distribution'

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

begin
  require 'rbgsl'
  HAS_GSL=true
rescue LoadError
  HAS_GSL=false
end
begin 
  require 'alglib'
  HAS_ALGIB=true
rescue LoadError
  HAS_ALGIB=false
end
# ++
# Modules for statistical analysis
# See first: 
# * Converter : several modules to import and export data
# * Vector: The base class of all analysis
# * Dataset: An union of vectors.
#
module Statsample
  VERSION = '0.5.0'
  SPLIT_TOKEN = ","
  autoload(:Database, 'statsample/converters')
  autoload(:Anova, 'statsample/anova')
  autoload(:Combination, 'statsample/combination')
  autoload(:CSV, 'statsample/converters')
  autoload(:PlainText, 'statsample/converters')
  autoload(:Excel, 'statsample/converters')
  autoload(:GGobi, 'statsample/converters')
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
  def self.load(filename)
    if File.exists? filename
      o=false
      File.open(filename,"r") {|fp| o=Marshal.load(fp) }
      o
    else
      false
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
  module HtmlSummary
      def add_line(n=nil)
          self << "<hr />"
      end
      def nl
          self << "<br />"
      end
      def add(text)
          self << ("<p>"+text.gsub("\n","<br />")+"</p>")
      end
      def parse_table(table)
          self << table.parse_html
      end
  end
  module ConsoleSummary
        def add_line(n=80)
            self << "-"*n+"\n"
        end
        def nl
            self << "\n"
        end
        def add(text)
            self << text
        end
        def parse_table(table)
            self << table.parse_console
        end
  end
  class ReportTable
    attr_reader :header
    def initialize(h=[])
        @rows=[]
        @max_cols=[]
        self.header=(h)
    end
    def add_row(row)
        row.each_index{|i|
            @max_cols[i]=row[i].to_s.size if @max_cols[i].nil? or row[i].to_s.size > @max_cols[i]
        }
        @rows.push(row)
    end
    def add_horizontal_line
        @rows.push(:hr)
    end
    def header=(h)
        h.each_index{|i|
            @max_cols[i]=h[i].to_s.size if @max_cols[i].nil? or h[i].to_s.size>@max_cols[i]
        }    
        @header=h
    end
    def parse_console_row(row)
        out="| "
        @max_cols.each_index{|i|
            if row[i].nil?
                out << " "*(@max_cols[i]+2)+"|"
            else
                t=row[i].to_s
                out << " "+t+" "*(@max_cols[i]-t.size+1)+"|"
            end
        }
        out << "\n"
        out
    end
    def parse_console_hr
        "-"*(@max_cols.inject(0){|a,v|a+v.size+3}+2)+"\n"
    end
    def parse_console
        out="\n"
        out << parse_console_hr
        out << parse_console_row(header)
        out << parse_console_hr
  
        @rows.each{|row|
            if row==:hr
               out << parse_console_hr 
            else
            out << parse_console_row(row)
            end
        }
        out << parse_console_hr
  
        out
    end
    def parse_html
        out="<table>\n"
        if header.size>0
        out << "<thead><th>"+header.join("</th><th>")+"</thead><tbody>"
        end
        out << "<tbody>\n"
        row_with_line=false
        @rows.each{|row|
            if row==:hr
                row_with_line=true
            else
                out << "<tr class='"+(row_with_line ? 'line':'')+"'><td>"
                out << row.join("</td><td>") +"</td>"
                out << "</tr>\n"
                row_with_line=false
            end
        }
        out << "</tbody></table>\n"
        out
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
