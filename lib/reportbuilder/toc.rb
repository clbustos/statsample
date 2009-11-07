class ReportBuilder
  # Table of contents
  # 
  class Toc
    attr_reader :entries
    def initialize
      @entries=[]
    end
    def add_entry(parent=nil)
      @entries.push()
    end
  end
end
