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
    def self.run(name=nil)
      name||=@@last_analysis
      raise "Analysis #{name} doesn't exists" unless stored_analysis[name]
      stored_analysis[name].run
    end
    def self.run_batch(name=nil)
      name||=@@last_analysis
      raise "Analysis #{name} doesn't exists" unless stored_analysis[name]
      puts stored_analysis[name].to_text
    end
    def self.to_text(name=nil)
      name||=@@last_analysis
      raise "Analysis #{name} doesn't exists" unless stored_analysis[name]
      stored_analysis[name].to_text
      
    end
    class Suite 
      attr_accessor :output
      attr_accessor :name
      attr_reader :block
      def initialize(name,opts=Hash.new(),&block)
        @name=name
        @block=block
        @attached=[]
        @output=opts[:output] || ::STDOUT
        
      end
      # Run the analysis, putting output on 
      def run
         @block.arity<1 ? instance_eval(&@block) : @block.call(self)
      end
      def echo(*args)
        @output.puts *args
      end
      def summary(obj)
        obj.summary
      end
      def generate(filename)
        ar=SuiteReportBuilder.new(name,&block)
        ar.generate(filename)
      end
      def to_text
        ar=SuiteReportBuilder.new(name, &block)
        ar.to_text
      end
      
      def attach(ds)
        @attached.push(ds)
      end
      def detach(ds=nil)
        if ds.nil?
          @attached.pop
        else
          @attached.delete(ds)
        end
      end
      ###
      # :section: R like methods
      ###
      
      # Retrieve names (fields) from dataset
      def names(ds)
        ds.fields
      end
      # Create a correlation matrix from a dataset
      def cor(ds)
        Statsample::Bivariate.correlation_matrix(ds)
      end
      # Create a variance/covariance matrix from a dataset
      def cov(ds)
        Statsample::Bivariate.covariate_matrix(ds)
      end
      # Create a Statsample::Vector
      def c(*args)
        Statsample::Vector[*args]
      end
      # Random generation for the normal distribution
      def rnorm(n,mean=0,sd=1)
        rng=Distribution::Normal.rng_ugaussian(mean,sd)
        Statsample::Vector.new_scale(n) { rng.call}
      end
      # Creates a new Statsample::Dataset
      # Each key is transformed into string
      def data_frame(vectors=Hash.new)
        vectors=vectors.inject({}) {|ac,v| ac[v[0].to_s]=v[1];ac}
        Statsample::Dataset.new(vectors)
      end
      def boxplot(*args)
        require 'tmpdir'
        bp=Statsample::Graph::Boxplot.new(*args)
        fn=Dir.tmpdir+"/bp_#{Time.now.to_f}.svg"
        File.open(fn,"w") {|fp| fp.write bp.to_svg}
        `xdg-open '#{fn}'`
      end
      ###
      # Other Shortcuts
      ###
      def lr(*args)
        Statsample::Regression.multiple(*args)
      end
      def pca(ds,opts=Hash.new)
        Statsample::Factor::PCA.new(ds,opts)
      end
      def dominance_analysis(*args)
        Statsample::DominanceAnalysis.new(*args)
      end
      def dominance_analysis_bootstrap(*args)
        Statsample::DominanceAnalysis::Bootstrap.new(*args)
      end
      
      def method_missing(name, *args,&block)
        @attached.reverse.each do |ds|
          return ds[name.to_s] if ds.fields.include? (name.to_s)
        end
        raise "Method #{name} doesn't exists"
      end
    end
    class SuiteReportBuilder < Suite
      attr_accessor :rb
      def initialize(name,&block)
        super(name,&block)
        @rb=ReportBuilder.new(:name=>name)
      end
      def generate(filename)
        run if @block
        @rb.save(filename)
      end
      def to_text
        run if @block
        @rb.to_text
      end
      def summary(o)
        @rb.add(o)
      end
      def echo(*args)
        args.each do |a|
          @rb.add(a)
        end
      end
      
      def boxplot(*args)
        
        bp=Statsample::Graph::Boxplot.new(*args)
        @rb.add(bp)
      end
      
      
    end
    
  end
end
