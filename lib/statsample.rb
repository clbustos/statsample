# = rubyss.rb - 

# Process files and databases for statistical purposes, with focus on 
# estimation of parameters for several types of samples (simple random, 
# stratified and multistage sampling).
#
# Copyright (C) 2008 Claudio Bustos
#
# Claudio Bustos mailto:clbustos@gmail.com

# :stopdoc:

$:.unshift(File.dirname(__FILE__))
$:.unshift(File.expand_path(File.dirname(__FILE__)+"/../ext"))

require 'delegate'
require 'matrix'


class Numeric
  def square ; self * self ; end
end


def create_test(*args,&proc) 
    description=args.shift
    fields=args
    [description, fields, Proc.new]
end

# Process files and databases for statistical purposes, with focus on 
# estimation of parameters for several types of samples (simple random, 
# stratified and multistage sampling).

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
        
    
    begin 
       require 'rubyss/rubyssopt'
    rescue LoadError
        module RubySS
            OPTIMIZED=false
        end
    end

#
# :startdoc:
#
module RubySS
    VERSION = '0.2.0'
    SPLIT_TOKEN = ","
	autoload(:Database, 'rubyss/converters')
    autoload(:Anova, 'rubyss/anova')
	autoload(:CSV, 'rubyss/converters')
	autoload(:Excel, 'rubyss/converters')
	autoload(:GGobi, 'rubyss/converters')
    autoload(:DominanceAnalysis, 'rubyss/dominanceanalysis')
	autoload(:HtmlReport, 'rubyss/htmlreport')
    autoload(:Mx, 'rubyss/converters')
	autoload(:Resample, 'rubyss/resample')
	autoload(:SRS, 'rubyss/srs')
	autoload(:Codification, 'rubyss/codification')
	autoload(:Reliability, 'rubyss/reliability')
	autoload(:Bivariate, 'rubyss/bivariate')
	autoload(:Multivariate, 'rubyss/multivariate')

	autoload(:Regression, 'rubyss/regression')
	autoload(:Test, 'rubyss/test')
    def self.load(filename)
        fp=File.open(filename,"r")
        o=Marshal.load(fp)
        fp.close
        o
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
        def initialize(header=[])
            @header=header
            @rows=[]
            @max_cols=[]
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
end

require 'rubyss/vector'
require 'rubyss/dataset'
require 'rubyss/crosstab'

