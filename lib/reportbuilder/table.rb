class ReportBuilder
  # Creates a table.
  # Use:
  #   table=ReportBuilder::Table.new(:header =>["id","city","name","code1","code2"])
  #   table.add_row([1, Table.rowspan("New York",3), "Ringo", Table.colspan("no code",2),nil])
  #   table.add_row([2, nil,"John", "ab-1","ab-2"])
  #   table.add_row([3, nil,"Paul", "ab-3"])
  #   table.add_hr
  #   table.add_row([4, "London","George", Table.colspan("ab-4",2),nil])
  #   puts table
  #     ==>
  #   -----------------------------------------
  #   | id | city     | name  | code1 | code2 |
  #   -----------------------------------------
  #   | 1  | New York | Ringo | no code       |
  #   | 2  |          | John  | ab-1  | ab-2  |
  #   | 3  |          | Paul  | ab-3  |       |
  #   -----------------------------------------
  #   | 4  | London   |George | ab-4          |
  #   -----------------------------------------
  class Table
    @@n=1 # :nodoc:
    
    DEFAULT_OPTIONS={
      :header =>  [],
      :name   =>   nil
    }
    # Array of headers
    attr_accessor :header, :name
    # Size for each column
    attr_reader :max_cols
    # Array of rows
    attr_reader :rows
    # Create a new table.
    # Options: :name, :header
    # Use:
    #   table=ReportBuilder::Table.new(:header =>["var1","var2"])
    def initialize(opts=Hash.new)
      raise ArgumentError,"opts should be a Hash" if !opts.is_a? Hash
      opts=DEFAULT_OPTIONS.merge opts
      if opts[:name].nil?
        @name= "Table #{@@n}"
        @@n+=1
      else
        @name=opts[:name]
      end
      @header=opts[:header]
      @rows=[]
      @max_cols=[]
    end
    # Adds a row
    #   table.add_row(%w{1 2})
    def add_row(row)
      @rows.push(row)
    end
    # Adds a horizontal rule
    #   table.add_hr
    def add_hr
      @rows.push(:hr)
    end
    alias_method  :add_horizontal_line, :add_hr
    # Adds a rowspan on a cell
    #   table.add_row(["a",table.rowspan("b",2)])
    def rowspan(data,n)
      Rowspan.new(data,n)
    end
    # Adds a colspan on a cell
    #   table.add_row(["a",table.colspan("b",2)])
    
    def colspan(data,n)
      Colspan.new(data,n)
    end
    def calculate_widths # :nodoc:
    @max_cols=[]
    rows_cal=[header]+@rows
    rows_cal.each{|row|
      next if row==:hr
      row.each_index{|i|
          if row[i].nil?
              next
          elsif row[i].is_a? Colspan
              size_total=row[i].data.to_s.size
              size_per_column=(size_total / row[i].cols)+1
              for mi in i...i+row[i].cols
                  @max_cols[mi] = size_per_column if @max_cols[mi].nil? or @max_cols[mi]<size_per_column
              end
          elsif row[i].is_a? Rowspan
              size=row[i].data.to_s.size
              @max_cols[i]= size if @max_cols[i].nil? or @max_cols[i] < size
          else
              
              size=row[i].to_s.size
              @max_cols[i]= size if @max_cols[i].nil? or @max_cols[i] < size
          end
      }
    }
    end
    def to_reportbuilder_text(generator)
      require 'reportbuilder/table/textgenerator'
      table_generator=ReportBuilder::Table::TextGenerator.new( generator, self)
      table_generator.generate
    end
    def to_reportbuilder_html(generator)
      require 'reportbuilder/table/htmlgenerator'
      table_generator=ReportBuilder::Table::HtmlGenerator.new(generator, self)
      table_generator.generate
    end

    def total_width # :nodoc:
      @max_cols.inject(0){|a,v| a+(v+3)}+1
    end
######################
#  INTERNAL CLASSES  #
######################
  
    class Rowspan # :nodoc:
      attr_accessor :data, :rows
      def initialize(data,rows)
          @data=data
          @rows=rows
      end
      def to_s
          @data.to_s
      end
    end
    
    class Colspan # :nodoc:
      attr_accessor :data, :cols
      def initialize(data,cols)
          @data=data
          @cols=cols
      end
      def to_s
          @data.to_s
      end
    end
  end
end

