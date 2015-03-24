# = spss.rb -
#
# Provides utilites for working with spss files
#
# Copyright (C) 2009 Claudio Bustos
#
# Claudio Bustos mailto:clbustos@gmail.com

module SPSS # :nodoc: all
  module Dictionary
    class Element
      def add(a)
        @elements.push(a)
      end

      def parse_elements(func = :to_s)
        @elements.collect{ |e| "   "+e.send(func) }.join("\n")
      end

      def init_with config
        config.each do |key, value|
            self.send(key.to_s + "=", value) if methods.include? key.to_s
        end
      end

      def initialize(config = {})
        @config = config
        @elements = []
      end
    end
    class Dictionary < Element
      attr_accessor :locale, :date_time, :row_count
      def initialize(config = {})
        super
        init_with ({
                :locale=>"en_US",
                :date_time=>Time.new().strftime("%Y-%m-%dT%H:%M:%S"),
                :row_count=>1
        })
        init_with config
      end

      def to_xml
        "<dictionary locale='#{@locale}' creationDateTime='#{@date_time}' rowCount='#{@row_count}' xmlns='http://xml.spss.com/spss/data'>\n"+parse_elements(:to_xml)+"\n</dictionary>"

      end
      def to_spss
        parse_elements(:to_spss)
      end
    end

    class MissingValue < Element
      attr_accessor :data, :type, :from, :to
      def initialize(data,type=nil)
        @data=data
        if type.nil? or type=="lowerBound" or type=="upperBound"
            @type=type
        else
            raise Exception,"Incorrect value for type"
        end
      end
      def to_xml
        "<missingValue data='#{@data}' "+(type.nil? ? "":"type='#{type}'")+"/>"
      end
    end
    class LabelSet
      attr_accessor
      def initialize(labels)
        @labels=labels
      end
      def parse_xml(name)
        "<valueLabelSet>\n   "+@labels.collect{|key,value| "<valueLabel label='#{key}' value='#{value}' />"}.join("\n   ")+"\n   <valueLabelVariable name='#{name}' />\n</valueLabelSet>"
      end
      def parse_spss()
        @labels.collect{|key,value| "#{key} '#{value}'"}.join("\n   ")
      end
    end
    class Variable < Element
      attr_accessor :aligment, :display_width, :label, :measurement_level, :name, :type, :decimals, :width, :type_format, :labelset, :missing_values
      def initialize(config={})
        super
        @@var_number||=1
        init_with({
          :aligment           =>  "left",
          :display_width      =>  8,
          :label              =>  "Variable #{@@var_number}",
          :measurement_level  =>  "SCALE",
          :name               =>  "var#{@@var_number}",
          :type               =>  0,
          :decimals           =>  2,
          :width              =>  10,
          :type_format        =>  "F",
          :labelset           => nil
        })
        init_with config
        @missing_values=[]
        @@var_number+=1
      end
      def to_xml
        labelset_s=(@labelset.nil?) ? "":"\n"+@labelset.parse_xml(@name)
        missing_values=(@missing_values.size>0) ? @missing_values.collect {|m| m.to_xml}.join("\n"):""
        "<variable aligment='#{@aligment}' displayWidth='#{@display_width}' label='#{@label}' measurementLevel='#{@measurement_level}' name='#{@name}' type='#{@type}'>\n<variableFormat decimals='#{@decimals}' width='#{@width}' type='#{@type_format}' />\n"+parse_elements(:to_xml)+missing_values+"</variable>"+labelset_s
      end
      def to_spss
        out=<<HERE
VARIABLE LABELS #{@name} '#{label}' .
VARIABLE ALIGMENT #{@name} (#{@aligment.upcase}) .
VARIABLE WIDTH #{@name} (#{@display_width}) .
VARIABLE LEVEL #{@name} (#{@measurement_level.upcase}) .
HERE
        if !@labelset.nil?
            out << "VALUE LABELS #{@name} "+labelset.parse_spss()+" ."
        end
        if @missing_values.size>0
            out << "MISSING VALUES #{@name} ("+@missing_values.collect{|m| m.data}.join(",")+") ."
        end
        out
      end
    end
  end
end
n=SPSS::Dictionary::Dictionary.new
ls=SPSS::Dictionary::LabelSet.new({1=>"Si",2=>"No"})
var1=SPSS::Dictionary::Variable.new
var1.labelset=ls
mv1=SPSS::Dictionary::MissingValue.new("-99")
var2=SPSS::Dictionary::Variable.new
n.add(var1)
n.add(var2)
var2.missing_values=[mv1]

File.open("dic_spss.sps","wb") {|f|
    f.puts n.to_spss
}
