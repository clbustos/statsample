require 'fileutils'
class ReportBuilder
  class Generator
    
    class Html < Generator
      PREFIX="html"
      attr_reader :toc
      def initialize(builder)
        super
        @body=""
        @toc=[]
        @table_n=1
        @entry_n=1
        @list_tables=[]
        @headers=[]
        @footers=[]
      end
      def parse
        parse_cycle(@builder)
      end
      def out
        out="<html><head><title>#{@builder.name}</title>"
        out << @headers.join("\n")
        out << "</head><body>\n"
        out << "<h1>#{@builder.name}</h1>"
        if (@list_tables.size>0) 
          out << "<div class='tot'><div class='title'>List of tables</div><ul>"
          @list_tables.each {|anchor,name|
            out << "<li><a href='#"+anchor+"'>#{name}</a></li>"
          }
          out << "</ul></div>\n"
        end
        if(@toc.size>0)
        out << "<div class='toc'><div class='title'>List of contents</div></div>"
          actual_level=0
          @toc.each do |anchor,name,level|
            if actual_level!=level
              if actual_level > level
                (actual_level-level).times { out << "</ul>\n"}
              else
                (level-actual_level).times { out << "<ul>\n"}
              end
            end
            out << "<li><a href='##{anchor}'>#{name}</a></li>\n"
            actual_level=level
          end
          actual_level.times { out << "</ul>\n"}
          out << "</div>\n"
        end
        out << @body
        out << @footers.join("\n")
        out << "</body></html>"
      end
      def add_js(js)
        if(File.exists? js)
          if(!File.exists? @builder.dir+"/js/"+File.basename(js))
            FileUtils.mkdir @builder.dir+"/js"
            FileUtils.cp js,@builder.dir+"/js/"+File.basename(js)
          end
          @headers.push("<script type='text/javascript' src='js/#{File.basename(js)}'></script>")
        end
      end
      
      def add_css(css)
        if(File.exists? css)
          if(!File.exists? @builder.dir+"/css/"+File.basename(css))
            FileUtils.mkdir @builder.dir+"/css"
            FileUtils.cp css,@builder.dir+"/css/"+File.basename(css)
          end
          @headers.push("<link rel='stylesheet' type='text/css' href='css/#{File.basename(css)}' />")
        end
      end
      
      
      def add_text(t)
        ws=(" "*parse_level*2)
        @body << ws << "<pre>#{t}</pre>\n"
      end
      def add_raw(t)
        ws=(" "*parse_level*2)
        @body << ws << t << "\n"
      end
      def add_toc_entry(name)
        anchor="toc_#{@entry_n}"
        @entry_n+=1
        @toc.push([anchor, name, parse_level])
        anchor
      end
      # Add an entry for a table
      # Returns the name of the anchor
      def add_table_entry(name)
        anchor="table_#{@table_n}"
        @table_n+=1
        @list_tables.push([anchor,name])
        anchor
      end
    end
  end
end
