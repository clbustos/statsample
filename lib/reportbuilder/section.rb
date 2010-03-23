# Creates a Section.
# A section have a name and contains other elements.
# Sections could be nested inside anothers

class ReportBuilder::Section
  @@n=1
  attr_reader :parent, :elements, :name
  def initialize(options=Hash.new, &block)
    if !options.has_key? :name
      @name="Section #{@@n}"
      @@n+=1
    else
      @name=options[:name]
    end
    @parent = nil
    @elements = []
    if block
      add(block)
    end
  end
  def parent=(sect)
    if sect.is_a? ReportBuilder::Section
      @parent=sect
    else
      raise ArgumentError("Parent should be a Section")
    end
  end

  def report_building_text(generator)
    generator.text(("="*generator.parse_level)+" "+name)
    generator.parse_cycle(self)
  end

  def report_building_html(g)
    htag="h#{g.parse_level+1}"
    anchor=g.toc_entry(name)
    g.html "<div class='section'><#{htag}>#{name}</#{htag}><a name='#{anchor}'></a>"
    g.parse_cycle(self)
    g.html "</div>"
  end
  def report_building_rtf(g)
    level=g.parse_level
    g.header(level,name)
    g.parse_cycle(self)
  end
  def add(element)
    if element.is_a? ReportBuilder::Section
      element.parent=self
    end
    @elements.push(element)
  end
end
