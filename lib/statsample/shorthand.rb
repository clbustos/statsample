class Object
  # Shorthand for Statsample::Analysis.store(*args,&block)
  def ss_analysis(*args,&block)
    Statsample::Analysis.store(*args,&block)
  end
end

module Statsample
  # Module which provide shorthands for many methods.
  module Shorthand
    ###
    # :section: R like methods
    ###
    def read_with_cache(klass, filename,opts=Hash.new, cache=true)
      file_ds=filename+".ds"
      if cache and (File.exists? file_ds and File.mtime(file_ds)>File.mtime(filename))
        ds=Statsample.load(file_ds)
      else
        ds=klass.read(filename)
        ds.save(file_ds) if cache
      end
      ds
    end
    # Import an Excel file. Cache result by default
    def read_excel(filename, opts=Hash.new, cache=true)
      read_with_cache(Statsample::Excel, filename, opts, cache)

    end
    # Import an CSV file. Cache result by default

    def read_csv
      read_with_cache(Statsample::CSV, filename, opts, cache)
    end
    
    # Retrieve names (fields) from dataset
    def names(ds)
      ds.fields
    end
    # Create a correlation matrix from a dataset
    def cor(ds)
      Statsample::Bivariate.correlation_matrix(ds)
    end

    # Create a correlation probability matrix from a dataset
    def corp(ds)
      Statsample::Bivariate.correlation_probability_matrix(ds)
    end

    # Create a variance/covariance matrix from a dataset
    def cov(ds)
      Statsample::Bivariate.covariance_matrix(ds)
    end
    # Create a Statsample::Vector
    # Analog to R's c
    def vector(*args)
      Statsample::Vector[*args]
    end
    # Random generation for the normal distribution
    def rnorm(n,mean=0,sd=1)
      rng=Distribution::Normal.rng(mean,sd)
      Statsample::Vector.new_scale(n) { rng.call}
    end
    # Creates a new Statsample::Dataset
    # Each key is transformed into string
    def dataset(vectors=Hash.new)
      vectors=vectors.inject({}) {|ac,v| ac[v[0].to_s]=v[1];ac}
      Statsample::Dataset.new(vectors)
    end
    alias :data_frame :dataset
    # Returns a Statsample::Graph::Boxplot
    def boxplot(*args)
      Statsample::Graph::Boxplot.new(*args)
    end
    # Returns a Statsample::Graph::Histogram
    def histogram(*args)
      Statsample::Graph::Histogram.new(*args)
    end
    
    # Returns a Statsample::Graph::Scatterplot
    def scatterplot(*args)
      Statsample::Graph::Scatterplot.new(*args)
    end
    # Returns a Statsample::Test::Levene
    def levene(*args)
      Statsample::Test::Levene.new(*args)
    end
    def principal_axis(*args)
      Statsample::Factor::PrincipalAxis.new(*args)
      
    end
    def polychoric(*args)
      Statsample::Bivariate::Polychoric.new(*args)
    end
    def tetrachoric(*args)
      Statsample::Bivariate::Tetrachoric.new(*args)
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
    def scale_analysis(*args)
      Statsample::Reliability::ScaleAnalysis.new(*args)
    end
    def skill_scale_analysis(*args)
      Statsample::Reliability::SkillScaleAnalysis.new(*args)
    end
    def multiscale_analysis(*args,&block)
      Statsample::Reliability::MultiScaleAnalysis.new(*args,&block)
    end
    def test_u(*args)
      Statsample::Test::UMannWhitney.new(*args)
    end
    module_function :test_u, :rnorm
  end
end
