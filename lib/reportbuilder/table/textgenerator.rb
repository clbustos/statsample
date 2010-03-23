class ReportBuilder
  class Table
    class TextGenerator < ElementGenerator

      def generate()
        t=@element
        t.calculate_widths
        total_width=t.total_width
        out="Table: #{t.name}\n"
        if t.header.size>0
          out+=parse_hr(total_width)+"\n"
          out+=parse_row(t,t.header)+"\n"
          out+=parse_hr(total_width)+"\n"
        end
        t.rows.each do |row|
          if row==:hr
            out+=parse_hr(total_width)+"\n"
          else
            out+=parse_row(t,row)+"\n"
          end
        end
        out+=parse_hr(total_width)+"\n"
        @generator.text(out)
      end
      # Parse a row
      def parse_row(t,row)
        row_ary=[]
        colspan_i=0
        row.each_index do |i|
          if colspan_i>0
            colspan_i-=1
          elsif row[i].is_a? ReportBuilder::Table::Colspan
            size = (i...(i+row[i].cols)).inject(0) {|a,v| a+t.max_cols[v]+3}
            size-=3
            row_ary.push(row[i].data.to_s+" "*(size - row[i].data.size))
            colspan_i=row[i].cols-1
          elsif row[i].nil?
            row_ary.push(" "*t.max_cols[i])
          else
            size=row[i].to_s.size
            #puts sprintf("%i : %s (%d-%d)",i,row[i].to_s,@max_cols[i], size)
            row_ary.push(row[i].to_s+" "*(t.max_cols[i] - size))
          end
        end
        "| "+row_ary.join(" | ")+" |"
      end
      # Parse a horizontal rule
      def parse_hr(l)
        "-"*l
      end
    end
  end
end
