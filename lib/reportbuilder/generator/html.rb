require 'fileutils'
class ReportBuilder
  class Generator
    
    class Html < Generator
      PREFIX="html"
      attr_reader :toc
      def initialize(builder, options)
        super
        @body=""
        @headers=[]
        @footers=[]
      end
      def parse
        # add_css(File.dirname(__FILE__)+"/../../../data/reportbuilder.css")
        # add_js(File.dirname(__FILE__)+"/../../../data/reportbuilder.js")
        parse_cycle(@builder)
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
      end

      
      def add_image(filename)
        if(File.exists? filename)
          if(!File.exists? @builder.dir+"/images/"+File.basename(filename))
            FileUtils.mkdir @builder.dir+"/images"
            FileUtils.cp filename, @builder.dir+"/images/"+File.basename(filename)
          end
        end
        "images/"+File.basename(filename)
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
        @body << ws << "<p>#{t}</p>\n"
      end
      def add_html(t)
        ws=(" "*parse_level*2)
        @body << ws << t << "\n"
      end
      def add_preformatted(t)
        ws=(" "*parse_level*2)
        @body << ws << "<pre>#{t}</pre>\n"
        
      end
        
    end
  end
end
