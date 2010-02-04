# Creates a Section
class ReportBuilder::Section
  @@n=1
  attr_reader :parent, :elements, :name
  def initialize(options={})
    if !options.has_key? :name
      @name="Section #{@nn}"
      @nn+=1
    else
      @name=options[:name]
    end
    @parent = nil
    @elements = []
  end
  def parent=(sect)
    if sect.is_a? ReportBuilder::Section
      @parent=sect
    else
      raise ArgumentError("Parent should be a Section")
    end
  end
  
  def to_reportbuilder_text(generator)
    generator.add_text(("="*generator.parse_level)+" "+name)
    generator.parse_cycle(self)
  end
  
  def to_reportbuilder_html(generator)
    htag="h#{generator.parse_level+1}"
    anchor=generator.add_toc_entry(name)
    generator.add_html "<div class='section'><#{htag}>#{name}</#{htag}><a name='#{anchor}'></a>"
    generator.parse_cycle(self)
    generator.add_html "</div>"
  end
  
  def add(element)
    if element.is_a? ReportBuilder::Section
      element.parent=self
    end
    @elements.push(element)
  end
end
