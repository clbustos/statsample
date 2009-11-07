# Creates a Section
class ReportBuilder::Section
  @@n=1
  attr_reader :parent, :elements, :name
  def initialize(name=nil)
    if name.nil?
      @name="Section #{@nn}"
      @nn+=1
    else
      @name=name
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
  
  def to_rb_text(generator)
    generator.add_text(("="*generator.parse_level)+" "+name)
    generator.parse_cycle(self)
  end
  
  def to_rb_html(generator)
    htag="h#{generator.parse_level+1}"
    anchor=generator.add_toc_entry(name)
    generator.add_raw "<div class='section'><#{htag}>#{name}</#{htag}><a name='#{anchor}'></a>"
    generator.parse_cycle(self)
    generator.add_raw "</div>"
  end
  
  def add(*elements)
    elements.each do |element|
      if element.is_a? ReportBuilder::Section
        element.parent=self
      end
      if element.respond_to?(:to_reportbuilder)
        @elements.push(element.to_reportbuilder)
      else
        @elements.push(element)
      end
    end
  end
end
