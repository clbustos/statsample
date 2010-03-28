require 'text-table'
class ReportBuilder
  class Table
    class TextBuilder < ElementBuilder
      def generate()
        
        t=@element
        @rowspans=[]
        @builder.text(t.name)
        return if t.header.size+t.rows.size==0
        table = Text::Table.new do |tt|
          tt.head=t.header if t.header.size>0
          tt.rows=t.rows.map {|row| parse_row(row)}
        end
        #pp table.rows
        @builder.text(table.to_s)
      end
      # Parse a row
      def parse_row(row)
        return :separator if row==:hr
        t=@element
        row_ary=[]
        real_i=0
        row.each_index do |i|
          extra=1
          
          while !@rowspans[real_i].nil? and @rowspans[real_i]>0
            @rowspans[real_i]-=1
            row_ary << ""
            real_i+=1
          end
          
          if row[i].is_a? ReportBuilder::Table::Rowspan
            @rowspans[real_i]=row[i].rows-1
            row_ary << row[i].to_s
          elsif row[i].is_a? ReportBuilder::Table::Colspan
            row_ary.push({:value=>row[i].to_s, :colspan=>row[i].cols})
            extra=row[i].cols
          elsif row[i].nil?
            row_ary.push("")
          else
            #size=row[i].to_s.size
            #puts sprintf("%i : %s (%d-%d)",i,row[i].to_s,@max_cols[i], size)
            row_ary.push(row[i].to_s)
          end
          real_i+=extra
        end
        row_ary
      end
    end
  end
end
