class ReportBuilder
  class Table
    class RtfBuilder < ElementBuilder
      include RTF
      def generate()
        @t=@element
        @rtf=@builder.rtf
        
        # Title
        
        @builder.header(6,@t.name)
        
        max_cols=@t.calculate_widths
        n_rows=@t.n_rows_no_hr+(@t.header.size>0 ? 1: 0)
        args=[n_rows, @t.n_columns]+max_cols.map{|m| m*@builder.options[:font_size]*10}
        @table=@rtf.table(*args)
        @table.border_width=@builder.options[:table_border_width]
        @rowspans=[]
        if @t.header.size>0
          @t.header.each_with_index do |th,i|
            @table[0][i] << th
          end
        end
        row_i=1
        next_with_hr=false
        @t.rows.each_with_index{|row|
          if row==:hr
            next_with_hr=true
            # Nothing
          else
            parse_row(row,row_i)
            if next_with_hr
              create_hr(row_i)
              next_with_hr=false
            end
            row_i+=1
          end
        }
        
      end
      def create_hr(row_i)
        (0...@t.n_columns).each {|i|
          @table[row_i][i].top_border_width=@builder.options[:table_hr_width]
        }
      end
      
      def parse_row(row,row_i)
        t=@element
        row_ary=[]
        real_i=0
        colspan_i=0
        row.each_index do |i|
          extra=1 
          while !@rowspans[real_i].nil? and @rowspans[real_i]>0
            @rowspans[real_i]-=1
            real_i+=1
          end
          if row[i].is_a? Table::Colspan
            @table[row_i][real_i] << row[i].data            
            colspan_i=row[i].cols-1
            extra=row[i].cols
          elsif row[i].nil?
            @table[row_i][i] << ""
          elsif row[i].is_a? Table::Rowspan
            @table[row_i][real_i] << row[i].data
            @rowspans[real_i]=row[i].rows-1
          else
            @table[row_i][real_i] << row[i].to_s
          end
          real_i+=extra
        end
      end
    end
  end
end
