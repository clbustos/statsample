module Statsample
	# Class to create crosstab of data
	# With this, you can create reports and do chi square test
	# The first vector will be at rows and the second will the the columns
	#
  class Crosstab
    include Summarizable
    attr_reader :v_rows, :v_cols
    attr_accessor :row_label, :column_label, :name, :percentage_row, :percentage_column, :percentage_total
    def initialize(v1, v2, opts=Hash.new)
      raise ArgumentError, "Vectors should be the same size" unless v1.size==v2.size
      @v_rows, @v_cols = Statsample.only_valid_clone(
        Daru::Vector.new(v1),
        Daru::Vector.new(v2))
      @cases          = @v_rows.size
      @row_label      = v1.name
      @column_label   = v2.name
      @name           = nil
      @percentage_row = @percentage_column = @percentage_total=false
      opts.each do |k,v|
        self.send("#{k}=",v) if self.respond_to? k
      end
      @name ||= _("Crosstab %s - %s") % [@row_label, @column_label]
    end	
    def rows_names
      @v_rows.factors.sort.reset_index!
    end
    def cols_names
      @v_cols.factors.sort.reset_index!
    end
    def rows_total
      @v_rows.frequencies
    end
    def cols_total
      @v_cols.frequencies
    end
    
    def frequencies
      base = rows_names.inject([]) do |s,row| 
        s += cols_names.collect { |col| [row,col] }
      end.inject({}) do |s,par|
        s[par]=0
        s
      end
      base.update(Daru::Vector.new(Statsample::vector_cols_matrix(@v_rows,@v_cols).to_a).frequencies)
    end
    def to_matrix
      f  = frequencies
      rn = rows_names
      cn = cols_names
      Matrix.rows(rn.collect{|row|
          cn.collect{|col| f[[row,col]]}
      })
    end
    def frequencies_by_row
    f=frequencies
    rows_names.inject({}){|sr,row|
      sr[row]=cols_names.inject({}) {|sc,col| sc[col]=f[[row,col]]; sc}
      sr
    }
    end
    def frequencies_by_col
      f=frequencies
      cols_names.inject({}){|sc,col| 
        sc[col]=rows_names.inject({}) {|sr,row| sr[row]=f[[row,col]]; sr}
        sc
      }
    end
    # Chi square, based on expected and real matrix
    def chi_square
      require 'statsample/test'
      Statsample::Test.chi_square(self.to_matrix, matrix_expected)
    end
    # Useful to obtain chi square
    def matrix_expected
      rn=rows_names
      cn=cols_names
      rt=rows_total
      ct=cols_total
      t=@v_rows.size
      m=rn.collect{|row|
        cn.collect{|col|
          (rt[row]*ct[col]).quo(t) 
          }
      }
      Matrix.rows(m)
    end
    def cols_empty_hash
      cols_names.inject({}) {|a,x| a[x]=0;a}
    end
    def report_building(builder)
      builder.section(:name=>@name) do |generator|
        fq=frequencies
        rn=rows_names
        cn=cols_names
        total=0
        total_cols=cols_empty_hash
        generator.text "Chi Square: #{chi_square}"
        generator.text(_("Rows: %s") % @row_label) unless @row_label.nil?
        generator.text(_("Columns: %s") % @column_label) unless @column_label.nil?
        
        t=ReportBuilder::Table.new(:name=>@name+" - "+_("Raw"), :header=>[""]+cols_names.collect {|c| @v_cols.index_of(c)}+[_("Total")])
        rn.each do |row|
          total_row=0
          t_row=[@v_rows.index_of(row)]
          cn.each do |col|
            data=fq[[row,col]]
            total_row+=fq[[row,col]]
            total+=fq[[row,col]]                    
            total_cols[col]+=fq[[row,col]]                    
            t_row.push(data)
          end
          t_row.push(total_row)
          t.row(t_row)
        end
        t.hr
        t_row=[_("Total")]
        cn.each do |v|
          t_row.push(total_cols[v])
        end
        t_row.push(total)
        t.row(t_row)
        generator.parse_element(t)
        
        if(@percentage_row)
          table_percentage(generator,:row)
        end
        if(@percentage_column)
        table_percentage(generator,:column)
        end
        if(@percentage_total)
        table_percentage(generator,:total)
        end
      end
    end
      
    
  
    def table_percentage(generator,type)
      fq=frequencies
      cn=cols_names
      rn=rows_names
      rt=rows_total
      ct=cols_total
      
      type_name=case type
        when :row     then  _("% Row")
        when :column  then  _("% Column")
        when :total   then  _("% Total")
      end
      
      t=ReportBuilder::Table.new(:name=>@name+" - "+_(type_name), :header=>[""]+cols_names.collect {|c| @v_cols.index_of(c) } + [_("Total")])
        rn.each do |row|
          t_row=[@v_rows.index_of(row)]
          cn.each do |col|
            total=case type
              when :row     then  rt[row]
              when :column  then  ct[col]
              when :total   then  @cases
            end
            data = sprintf("%0.2f%%", fq[[row,col]]*100.0/ total )
            t_row.push(data)
          end
          total=case type
            when :row     then  rt[row]
            when :column  then  @cases
            when :total   then  @cases
          end              
          t_row.push(sprintf("%0.2f%%", rt[row]*100.0/total))
          t.row(t_row)
        end
        
        t.hr
        t_row=[_("Total")]
        cn.each{|col|
          total=case type
            when :row     then  @cases
            when :column  then  ct[col]
            when :total   then  @cases
          end
          t_row.push(sprintf("%0.2f%%", ct[col]*100.0/total))
        }
      t_row.push("100%")
      t.row(t_row)
      generator.parse_element(t)
    end
  end
end
