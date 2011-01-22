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
  #  # puts and pp are overloaded, so its output will be 
  #  # redirected to report. 
  #  # Summary method call 'report_building' on the object, 
  #  # instead of calling summary
  #  an1.generate("report.html")
  module Analysis
    @@stored_analysis={}
    @@last_analysis=nil
    def self.stored_analysis
      @@stored_analysis
    end
    def self.last
      @@stored_analysis[@@last_analysis]
    end
    def self.store(name,opts=Hash.new,&block)
      raise "You should provide a block" if !block
      @@last_analysis=name
      @@stored_analysis[name]=Suite.new(name,opts,&block)
    end
    # Run analysis +name+
    # Withoud arguments, run the latest analysis
    # Only 'echo' will be returned to screen
    def self.run(name=nil)
      name||=@@last_analysis
      raise "Analysis #{name} doesn't exists" unless stored_analysis[name]
      stored_analysis[name].run
    end
    # Run analysis and return to screen all
    # echo and summary callings
    def self.run_batch(name=nil)
      name||=@@last_analysis
      raise "Analysis #{name} doesn't exists" unless stored_analysis[name]
      puts stored_analysis[name].to_text
    end
    def self.save(filename, name=nil)
      name||=@@last_analysis
      raise "Analysis #{name} doesn't exists" unless stored_analysis[name]
      puts stored_analysis[name].generate(filename)
    end
    
    
    # Run analysis and return as string
    # output of echo callings
    def self.to_text(name=nil)
      name||=@@last_analysis
      raise "Analysis #{name} doesn't exists" unless stored_analysis[name]
      stored_analysis[name].to_text
      
    end
  end
end
