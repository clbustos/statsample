require 'statsample/analysis/suite'
require 'statsample/analysis/suitereportbuilder'

module Statsample
  # DSL to create analysis without hazzle. 
  # * Shortcuts methods to avoid use complete namescapes, many based on R  
  # * Attach/detach vectors to workspace, like R
  # == Example
  #  an1=Statsample::Analysis.store(:first) do
  #    # Load excel file with x,y,z vectors
  #    ds=excel('data.xls')
  #    # See variables on ds dataset
  #    names(ds) 
  #    # Attach the vectors to workspace, like R
  #    attach(ds)
  #    # vector 'x' is attached to workspace like a method,
  #    # so you can use like any variable
  #    mean,sd=x.mean, x.sd 
  #    # Shameless R robbery
  #    a=c( 1:10)
  #    b=c(21:30)
  #    summary(cor(ds)) # Call summary method on correlation matrix
  #  end
  #  # You can run the analysis by its name
  #  Statsample::Analysis.run(:first)
  #  # or using the returned variables
  #  an1.run
  #  # You can also generate a report using ReportBuilder.
  #  # .summary() method call 'report_building' on the object, 
  #  # instead of calling text summary
  #  an1.generate("report.html")
  module Analysis
    @@stored_analysis={}
    @@last_analysis=nil
    def self.clear_analysis
      @@stored_analysis.clear
    end
    def self.stored_analysis
      @@stored_analysis
    end
    def self.last
      @@stored_analysis[@@last_analysis]
    end
    def self.store(name, opts=Hash.new,&block)
      raise "You should provide a block" if !block
      @@last_analysis=name
      opts={:name=>name}.merge(opts)
      @@stored_analysis[name]=Suite.new(opts,&block)
    end
    # Run analysis +*args+
    # Without arguments, run all stored analysis
    # Only 'echo' will be returned to screen
    def self.run(*args)
      args=stored_analysis.keys if args.size==0
      raise "Analysis #{args} doesn't exists" if (args - stored_analysis.keys).size>0
      args.each do |name|
        stored_analysis[name].run
      end
    end

    # Add analysis +*args+ to an reportbuilder object.
    # Without arguments, add all stored analysis
    # Each analysis is wrapped inside a ReportBuilder::Section object
    # This is the method is used by save() and to_text()
    
    def self.add_to_reportbuilder(rb, *args)
      args=stored_analysis.keys if args.size==0
      raise "Analysis #{name} doesn't exists" if (args - stored_analysis.keys).size>0
      args.each do |name|
        section=ReportBuilder::Section.new(:name=>stored_analysis[name].name)
        rb_an=stored_analysis[name].add_to_reportbuilder(section)
        rb.add(section)        
        rb_an.run
      end
    end
    
    # Save the analysis on a file
    # Without arguments, add all stored analysis    
    def self.save(filename, *args)
      rb=ReportBuilder.new(:name=>filename)
      add_to_reportbuilder(rb, *args)
      rb.save(filename)
    end
    
    # Run analysis and return as string
    # output of echo callings
    # Without arguments, add all stored analysis
    
    def self.to_text(*args)
      rb=ReportBuilder.new(:name=>"Analysis #{Time.now}")
      add_to_reportbuilder(rb, *args)
      rb.to_text
    end
    # Run analysis and return to screen all
    # echo and summary callings
    def self.run_batch(*args)
      puts to_text(*args)
    end    
  end
end
