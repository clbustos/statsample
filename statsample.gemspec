# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "statsample"
  s.version = "1.1.0.20110912141756"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Claudio Bustos"]
  s.date = "2013-19-04"
  s.description = "A suite for basic and advanced statistics on Ruby. Tested on Ruby 1.8.7, 1.9.1, 1.9.2, 1.9.3 and JRuby 1.4 (Ruby 1.8.7 compatible).\n\nInclude:\n* Descriptive statistics: frequencies, median, mean, standard error, skew, kurtosis (and many others).\n* Imports and exports datasets from and to Excel, CSV and plain text files.\n* Correlations: Pearson's r, Spearman's rank correlation (rho), point biserial, tau a, tau b and  gamma.  Tetrachoric and Polychoric correlation provides by +statsample-bivariate-extension+ gem.\n* Intra-class correlation\n* Anova: generic and vector-based One-way ANOVA and Two-way ANOVA, with contrasts for One-way ANOVA.\n* Tests: F, T, Levene, U-Mannwhitney.\n* Regression: Simple, Multiple (OLS), Probit  and Logit\n* Factorial Analysis: Extraction (PCA and Principal Axis), Rotation (Varimax, Equimax, Quartimax) and Parallel Analysis and Velicer's MAP test, for estimation of number of factors.\n* Reliability analysis for simple scale and a DSL to easily analyze multiple scales using factor analysis and correlations, if you want it.\n* Dominance Analysis, with multivariate dependent and bootstrap (Azen & Budescu)\n* Sample calculation related formulas\n* Structural Equation Modeling (SEM), using R libraries +sem+ and +OpenMx+\n* Creates reports on text, html and rtf, using ReportBuilder gem\n* Graphics: Histogram, Boxplot and Scatterplot"
  s.email = ["clbustos@gmail.com"]
  s.executables = ["statsample"]
  s.extra_rdoc_files = ["History.txt", "LICENSE.txt", "Manifest.txt", "README.txt", "references.txt"]
  s.files = ["History.txt", "LICENSE.txt", "Manifest.txt", "README.txt", "Rakefile", "benchmarks/correlation_matrix_15_variables.rb", "benchmarks/correlation_matrix_5_variables.rb", "benchmarks/correlation_matrix_methods/correlation_matrix.ds", "benchmarks/correlation_matrix_methods/correlation_matrix.html", "benchmarks/correlation_matrix_methods/correlation_matrix.rb", "benchmarks/correlation_matrix_methods/correlation_matrix.xls", "benchmarks/correlation_matrix_methods/correlation_matrix_gsl_ruby.ods", "benchmarks/correlation_matrix_methods/correlation_matrix_with_graphics.ods", "benchmarks/correlation_matrix_methods/results.ds", "benchmarks/factor_map.rb", "benchmarks/helpers_benchmark.rb", "bin/statsample", "data/locale/es/LC_MESSAGES/statsample.mo", "doc_latex/manual/equations.tex", "examples/boxplot.rb", "examples/correlation_matrix.rb", "examples/dataset.rb", "examples/dominance_analysis.rb", "examples/dominance_analysis_bootstrap.rb", "examples/histogram.rb", "examples/icc.rb", "examples/levene.rb", "examples/multiple_regression.rb", "examples/multivariate_correlation.rb", "examples/parallel_analysis.rb", "examples/polychoric.rb", "examples/principal_axis.rb", "examples/reliability.rb", "examples/scatterplot.rb", "examples/t_test.rb", "examples/tetrachoric.rb", "examples/u_test.rb", "examples/vector.rb", "examples/velicer_map_test.rb", "grab_references.rb", "lib/spss.rb", "lib/statsample.rb", "lib/statsample/analysis.rb", "lib/statsample/anova.rb", "lib/statsample/anova/contrast.rb", "lib/statsample/anova/oneway.rb", "lib/statsample/anova/twoway.rb", "lib/statsample/bivariate.rb", "lib/statsample/bivariate/pearson.rb", "lib/statsample/codification.rb", "lib/statsample/converter/csv.rb", "lib/statsample/converter/spss.rb", "lib/statsample/converters.rb", "lib/statsample/crosstab.rb", "lib/statsample/dataset.rb", "lib/statsample/dominanceanalysis.rb", "lib/statsample/dominanceanalysis/bootstrap.rb", "lib/statsample/factor.rb", "lib/statsample/factor/map.rb", "lib/statsample/factor/parallelanalysis.rb", "lib/statsample/factor/pca.rb", "lib/statsample/factor/principalaxis.rb", "lib/statsample/factor/rotation.rb", "lib/statsample/graph.rb", "lib/statsample/graph/boxplot.rb", "lib/statsample/graph/histogram.rb", "lib/statsample/graph/scatterplot.rb", "lib/statsample/histogram.rb", "lib/statsample/matrix.rb", "lib/statsample/mle.rb", "lib/statsample/mle/logit.rb", "lib/statsample/mle/normal.rb", "lib/statsample/mle/probit.rb", "lib/statsample/multiset.rb", "lib/statsample/regression.rb", "lib/statsample/regression/binomial.rb", "lib/statsample/regression/binomial/logit.rb", "lib/statsample/regression/binomial/probit.rb", "lib/statsample/regression/multiple.rb", "lib/statsample/regression/multiple/alglibengine.rb", "lib/statsample/regression/multiple/baseengine.rb", "lib/statsample/regression/multiple/gslengine.rb", "lib/statsample/regression/multiple/matrixengine.rb", "lib/statsample/regression/multiple/rubyengine.rb", "lib/statsample/regression/simple.rb", "lib/statsample/reliability.rb", "lib/statsample/reliability/icc.rb", "lib/statsample/reliability/multiscaleanalysis.rb", "lib/statsample/reliability/scaleanalysis.rb", "lib/statsample/reliability/skillscaleanalysis.rb", "lib/statsample/resample.rb", "lib/statsample/rserve_extension.rb", "lib/statsample/shorthand.rb", "lib/statsample/srs.rb", "lib/statsample/test.rb", "lib/statsample/test/bartlettsphericity.rb", "lib/statsample/test/chisquare.rb", "lib/statsample/test/f.rb", "lib/statsample/test/kolmogorovsmirnov.rb", "lib/statsample/test/levene.rb", "lib/statsample/test/t.rb", "lib/statsample/test/umannwhitney.rb", "lib/statsample/vector.rb", "lib/statsample/vector/gsl.rb", "po/es/statsample.mo", "po/es/statsample.po", "po/statsample.pot", "references.txt", "setup.rb", "test/fixtures/bank2.dat", "test/fixtures/correlation_matrix.rb", "test/fixtures/crime.txt", "test/fixtures/hartman_23.matrix", "test/fixtures/repeated_fields.csv", "test/fixtures/test_binomial.csv", "test/fixtures/test_csv.csv", "test/fixtures/test_xls.xls", "test/fixtures/tetmat_matrix.txt", "test/fixtures/tetmat_test.txt", "test/helpers_tests.rb", "test/test_analysis.rb", "test/test_anova_contrast.rb", "test/test_anovaoneway.rb", "test/test_anovatwoway.rb", "test/test_anovatwowaywithdataset.rb", "test/test_anovawithvectors.rb", "test/test_bartlettsphericity.rb", "test/test_bivariate.rb", "test/test_codification.rb", "test/test_crosstab.rb", "test/test_csv.rb", "test/test_dataset.rb", "test/test_dominance_analysis.rb", "test/test_factor.rb", "test/test_factor_map.rb", "test/test_factor_pa.rb", "test/test_ggobi.rb", "test/test_gsl.rb", "test/test_histogram.rb", "test/test_logit.rb", "test/test_matrix.rb", "test/test_mle.rb", "test/test_multiset.rb", "test/test_regression.rb", "test/test_reliability.rb", "test/test_reliability_icc.rb", "test/test_reliability_skillscale.rb", "test/test_resample.rb", "test/test_rserve_extension.rb", "test/test_srs.rb", "test/test_statistics.rb", "test/test_stest.rb", "test/test_stratified.rb", "test/test_test_f.rb", "test/test_test_kolmogorovsmirnov.rb", "test/test_test_t.rb", "test/test_umannwhitney.rb", "test/test_vector.rb", "test/test_xls.rb", "web/Rakefile"]
  s.homepage = "http://ruby-statsample.rubyforge.org/"
  s.post_install_message = "***************************************************\nThanks for installing statsample.\n\nOn *nix, you could install statsample-optimization\nto retrieve gems gsl, statistics2 and a C extension\nto speed some methods.\n\n  $ sudo gem install statsample-optimization\n\nOn Ubuntu, install  build-essential and libgsl0-dev \nusing apt-get. Compile ruby 1.9x from \nsource code first.\n\n  $ sudo apt-get install build-essential libgsl0-dev\n\n\n*****************************************************\n"
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "ruby-statsample"
  s.rubygems_version = "1.8.10"
  s.summary = "A suite for basic and advanced statistics on Ruby"
  s.test_files = ["test/test_ggobi.rb", "test/test_vector.rb", "test/test_crosstab.rb", "test/test_bivariate.rb", "test/test_dominance_analysis.rb", "test/test_analysis.rb", "test/test_dataset.rb", "test/test_test_t.rb", "test/test_regression.rb", "test/test_reliability_icc.rb", "test/test_histogram.rb", "test/test_multiset.rb", "test/test_logit.rb", "test/test_xls.rb", "test/test_test_kolmogorovsmirnov.rb", "test/test_factor_map.rb", "test/test_stratified.rb", "test/test_rserve_extension.rb", "test/test_reliability_skillscale.rb", "test/test_anova_contrast.rb", "test/test_anovaoneway.rb", "test/test_matrix.rb", "test/test_reliability.rb", "test/test_anovatwowaywithdataset.rb", "test/test_factor_pa.rb", "test/test_factor.rb", "test/test_resample.rb", "test/test_anovawithvectors.rb", "test/test_bartlettsphericity.rb", "test/test_statistics.rb", "test/test_stest.rb", "test/test_srs.rb", "test/test_test_f.rb", "test/test_csv.rb", "test/test_anovatwoway.rb", "test/test_gsl.rb", "test/test_mle.rb", "test/test_umannwhitney.rb", "test/test_codification.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<spreadsheet>, ["~> 0.6.5"])
      s.add_runtime_dependency(%q<reportbuilder>, ["~> 1.4"])
      s.add_runtime_dependency(%q<minimization>, ["~> 0.2.0"])
      s.add_runtime_dependency(%q<fastercsv>, ["> 0"])
      s.add_runtime_dependency(%q<dirty-memoize>, ["~> 0.0"])
      s.add_runtime_dependency(%q<extendmatrix>, ["~> 0.3.1"])
      s.add_runtime_dependency(%q<statsample-bivariate-extension>, ["> 0"])
      s.add_runtime_dependency(%q<rserve-client>, ["~> 0.2.5"])
      s.add_runtime_dependency(%q<rubyvis>, ["~> 0.5.0"])
      s.add_runtime_dependency(%q<distribution>, ["~> 0.3"])
      s.add_development_dependency(%q<hoe>, ["~> 0"])
      s.add_development_dependency(%q<shoulda>, ["~> 0"])
      s.add_development_dependency(%q<minitest>, ["~> 2.0"])
      s.add_development_dependency(%q<rserve-client>, ["~> 0"])
      s.add_development_dependency(%q<gettext>, ["~> 2.3.8"])
      s.add_development_dependency(%q<mocha>, ["~> 0"])
      s.add_development_dependency(%q<hoe-git>, ["~> 1.5.0"])
      s.add_development_dependency(%q<hoe>, ["~> 2.12"])
      s.add_development_dependency(%q<rspec>, ["~> 2.13.0"])
      s.add_development_dependency(%q<rspec-core>, ["~> 2.13.1"])
      s.add_development_dependency(%q<rspec-mocks>, ["~> 2.13.0"])
      s.add_development_dependency(%q<rspec-expectations>, ["~> 2.13.0"])
    else
      s.add_dependency(%q<spreadsheet>, ["~> 0.6.5"])
      s.add_dependency(%q<reportbuilder>, ["~> 1.4"])
      s.add_dependency(%q<minimization>, ["~> 0.2.0"])
      s.add_dependency(%q<fastercsv>, ["> 0"])
      s.add_dependency(%q<dirty-memoize>, ["~> 0.0"])
      s.add_dependency(%q<extendmatrix>, ["~> 0.3.1"])
      s.add_dependency(%q<statsample-bivariate-extension>, ["> 0"])
      s.add_dependency(%q<rserve-client>, ["~> 0.2.5"])
      s.add_dependency(%q<rubyvis>, ["~> 0.5.0"])
      s.add_dependency(%q<distribution>, ["~> 0.3"])
      s.add_dependency(%q<hoe>, ["~> 0"])
      s.add_dependency(%q<shoulda>, ["~> 0"])
      s.add_dependency(%q<minitest>, ["~> 2.0"])
      s.add_dependency(%q<rserve-client>, ["~> 0"])
      s.add_dependency(%q<gettext>, ["~> 2.3.8"])
      s.add_dependency(%q<mocha>, ["~> 0"])
      s.add_dependency(%q<hoe-git>, ["~> 1.5.0"])
      s.add_dependency(%q<hoe>, ["~> 2.12"])
      s.add_dependency(%q<rspec>, ["~> 2.13.0"])
      s.add_dependency(%q<rspec-core>, ["~> 2.13.1"])
      s.add_dependency(%q<rspec-mocks>, ["~> 2.13.0"])
      s.add_dependency(%q<rspec-expectations>, ["~> 2.13.0"])
    end
  else
    s.add_dependency(%q<spreadsheet>, ["~> 0.6.5"])
    s.add_dependency(%q<reportbuilder>, ["~> 1.4"])
    s.add_dependency(%q<minimization>, ["~> 0.2.0"])
    s.add_dependency(%q<fastercsv>, ["> 0"])
    s.add_dependency(%q<dirty-memoize>, ["~> 0.0"])
    s.add_dependency(%q<extendmatrix>, ["~> 0.3.1"])
    s.add_dependency(%q<statsample-bivariate-extension>, ["> 0"])
    s.add_dependency(%q<rserve-client>, ["~> 0.2.5"])
    s.add_dependency(%q<rubyvis>, ["~> 0.5.0"])
    s.add_dependency(%q<distribution>, ["~> 0.3"])
    s.add_dependency(%q<hoe>, ["~> 0"])
    s.add_dependency(%q<shoulda>, ["~> 0"])
    s.add_dependency(%q<minitest>, ["~> 2.0"])
    s.add_dependency(%q<rserve-client>, ["~> 0"])
    s.add_dependency(%q<gettext>, ["~> 2.3.8"])
    s.add_dependency(%q<mocha>, ["~> 0"])
    s.add_dependency(%q<hoe-git>, ["~> 1.5.0"])
    s.add_dependency(%q<hoe>, ["~> 2.12"])
    s.add_dependency(%q<rspec>, ["~> 2.13.0"])
    s.add_dependency(%q<rspec-core>, ["~> 2.13.1"])
    s.add_dependency(%q<rspec-mocks>, ["~> 2.13.0"])
    s.add_dependency(%q<rspec-expectations>, ["~> 2.13.0"])
  end
end
