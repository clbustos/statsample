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

    # Import an Excel file. Cache result by default
    def read_excel(filename, opts=Hash.new)
      Daru::DataFrame.from_excel filename, opts
    end

    # Import an CSV file. Cache result by default
    def read_csv(filename, opts=Hash.new)
      Daru::DataFrame.from_csv filename, opts
    end
    
    # Retrieve names (fields) from dataset
    def names(ds)
      ds.vectors.to_a
    end
    # Create a correlation matrix from a dataset
    def cor(ds)
      Statsample::Bivariate.correlation_matrix(ds)
    end
    # Create a variance/covariance matrix from a dataset
    def cov(ds)
      Statsample::Bivariate.covariate_matrix(ds)
    end
    # Create a Daru::Vector
    # Analog to R's c
    def vector(*args)
      Daru::Vector[*args]
    end
    # Random generation for the normal distribution
    def rnorm(n,mean=0,sd=1)
      rng=Distribution::Normal.rng(mean,sd)
      Daru::Vector.new_with_size(n) { rng.call}
    end
    # Creates a new Daru::DataFrame
    # Each key is transformed into a Symbol wherever possible.
    def dataset(vectors=Hash.new)
      vectors = vectors.inject({}) do |ac,v| 
        n     = v[0].respond_to?(:to_sym) ? v[0].to_sym : v[0] 
        ac[n] = v[1]
        ac
      end
      Daru::DataFrame.new(vectors)
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
