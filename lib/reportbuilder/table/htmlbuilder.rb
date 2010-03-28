class ReportBuilder
  class Table
    class HtmlBuilder < ElementBuilder
      def generate()
        t=@element
        anchor=@builder.table_entry(t.name)
        out="<a name='#{anchor}'></a><table><caption>#{t.name}</caption>"
        @rowspans=[]
        if t.header.size>0
          out+="<thead>"+parse_row(t,t.header,"th")+"</thead>\n"
        end
        out+="<tbody>\n"
        next_class=""
        t.rows.each{|row|
          if row==:hr
            next_class="top"
          else
            class_tag=(next_class=="")?"":" class ='#{next_class}' "
            out+="<tr#{class_tag}>"+parse_row(t,row)+"</tr>\n"
            next_class=""
          end
        }
        out+="</tbody>\n</table>\n"
        @builder.html(out)
      end
      def parse_row(t,row,tag="td")
        row_ary=[]
        real_i=0
        row.each_index do |i|
          extra=1 
          while !@rowspans[real_i].nil? and @rowspans[real_i]>0
            @rowspans[real_i]-=1
            row_ary << ""
            real_i+=1
          end
          
          if row[i].is_a? Table::Colspan
            row_ary.push(sprintf("<%s colspan=\"%d\">%s</%s>",tag, row[i].cols, row[i].data,tag))
          elsif row[i].nil?
            row_ary.push("<#{tag}></#{tag}>")
          elsif row[i].is_a? Table::Rowspan
            row_ary.push(sprintf("<%s rowspan=\"%d\">%s</%s>", tag, row[i].rows, row[i].data, tag))
            @rowspans[real_i]=row[i].rows-1
          else
            row_ary.push("<#{tag}>#{row[i]}</#{tag}>")
          end
          real_i+=extra
          
        end
        row_ary.join("")
      end
    end
  end
end
