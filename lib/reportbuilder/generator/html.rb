require 'fileutils'
class ReportBuilder
  class Generator
    class Html < Generator
      PREFIX="html"
      attr_reader :directory
      def initialize(builder, options)
        super
        @directory = @options.delete :directory
        @body=""
        @headers=[]
        @footers=[]
      end
      def default_options
        {:directory => Dir.pwd}
      end
      def basic_css
        <<-HERE
        <style>
        body {
          margin:0;
          padding:1em;
        }
        table {
          border-collapse: collapse;

        }
        table td {
          border: 1px solid black;
        }
        .section {
          margin:0.5em;
        }
        </style>
        HERE
      end
      def out
        out= <<-HERE
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html;charset=utf-8" >
<title>#{@builder.name}</title>
#{basic_css}
        HERE
        out << @headers.join("\n")
        out << "</head><body>\n"
        out << "<h1>#{@builder.name}</h1>"
        if(@toc.size>0)                      
        out << "<div id='toc'><div class='title'>List of contents</div>\n"
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
        if (@list_tables.size>0)
          out << "<div class='tot'><div class='title'>List of tables</div><ul>"
          @list_tables.each {|anchor,name|
            out << "<li><a href='#"+anchor+"'>#{name}</a></li>"
          }
          out << "</ul></div>\n"
        end

        out << @body
        out << @footers.join("\n")
        out << "</body></html>"
        out
      end
      def js(js)
        if(File.exists? js)
          if(!File.exists? @directory+"/js/"+File.basename(js))
            FileUtils.mkdir @directory+"/js"
            FileUtils.cp js,@directory+"/js/"+File.basename(js)
          end
          @headers.push("<script type='text/javascript' src='js/#{File.basename(js)}'></script>")
        end
      end

      def css(css)
        if(File.exists? css)
          if(!File.exists? @directory+"/css/"+File.basename(css))
            FileUtils.mkdir @directory+"/css"
            FileUtils.cp css, @directory+"/css/"+File.basename(css)
          end
          @headers.push("<link rel='stylesheet' type='text/css' href='css/#{File.basename(css)}' />")
        end
      end


      def text(t)
        ws=(" "*parse_level*2)
        @body << ws << "<p>#{t}</p>\n"
      end
      def html(t)
        ws=(" "*parse_level*2)
        @body << ws << t << "\n"
      end
      def preformatted(t)
        ws=(" "*parse_level*2)
        @body << ws << "<pre>#{t}</pre>\n"

      end

    end
  end
end
