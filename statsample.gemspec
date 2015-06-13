$:.unshift File.expand_path("../lib/", __FILE__)

require 'statsample/version'
require 'date'

Statsample::DESCRIPTION = <<MSG
A suite for basic and advanced statistics on Ruby. Tested on CRuby 1.9.3, 2.0.0
and 2.1.1. See `.travis.yml` for more information.

Include:

- Descriptive statistics: frequencies, median, mean,
standard error, skew, kurtosis (and many others).
- Correlations: Pearson's r, Spearman's rank correlation (rho), point biserial,
tau a, tau b and  gamma. Tetrachoric and Polychoric correlation provides by
statsample-bivariate-extension gem.
- Intra-class correlation
- Anova: generic and vector-based One-way ANOVA and Two-way ANOVA, with contrasts for
One-way ANOVA.
- Tests: F, T, Levene, U-Mannwhitney.
- Regression: Simple, Multiple (OLS), Probit and Logit
- Factorial Analysis: Extraction (PCA and Principal Axis), Rotation (Varimax,
Equimax, Quartimax) and Parallel Analysis and Velicer's MAP test, for
estimation of number of factors.
- Reliability analysis for simple scale and a DSL to easily analyze multiple
scales using factor analysis and correlations, if you want it.
- Dominance Analysis, with multivariate dependent and bootstrap (Azen & Budescu)
- Sample calculation related formulas
- Structural Equation Modeling (SEM), using R libraries +sem+ and +OpenMx+
- Creates reports on text, html and rtf, using ReportBuilder gem
- Graphics: Histogram, Boxplot and Scatterplot.
MSG

Statsample::POSTINSTALL = <<MSG
***************************************************

Thanks for installing statsample.

*****************************************************
MSG

Gem::Specification.new do |s|
  s.name = "statsample"
  s.version = Statsample::VERSION
  s.date = Date.today.to_s
  s.homepage = "https://github.com/sciruby/statsample"

  s.authors = ["Claudio Bustos", "Carlos Agarie"]
  s.email = ["clbustos@gmail.com", "carlos@onox.com.br"]

  s.summary = "A suite for basic and advanced statistics on Ruby"
  s.description = Statsample::DESCRIPTION
  s.post_install_message = Statsample::POSTINSTALL

  s.rdoc_options = ["--main", "README.md"]
  s.extra_rdoc_files = ["History.txt", "LICENSE.txt", "README.md", "references.txt"]
  s.require_paths = ["lib"]

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.add_runtime_dependency 'daru', '~> 0.1'
  s.add_runtime_dependency 'spreadsheet', '~> 1.0.3'
  s.add_runtime_dependency 'reportbuilder', '~> 1.4'
  s.add_runtime_dependency 'minimization', '~> 0.2'
  s.add_runtime_dependency 'dirty-memoize', '~> 0.0.4'
  s.add_runtime_dependency 'extendmatrix', '~> 0.4'
  s.add_runtime_dependency 'rserve-client', '~> 0.3'
  s.add_runtime_dependency 'rubyvis', '~> 0.6.1'
  s.add_runtime_dependency 'distribution', '~> 0.7'
  s.add_runtime_dependency 'awesome_print', '~> 1.6'

  s.add_development_dependency 'bundler', '~> 1.10'
  s.add_development_dependency 'rake', '~> 10.4'
  s.add_development_dependency 'rdoc', '~> 4.2'
  s.add_development_dependency 'shoulda', '~> 3.5'
  s.add_development_dependency 'shoulda-matchers', '~> 2.2'
  s.add_development_dependency 'minitest', '~> 5.7'
  s.add_development_dependency 'gettext', '~> 3.1'
  s.add_development_dependency 'mocha', '~> 1.1'
  s.add_development_dependency 'nmatrix', '~> 0.1.0'
  s.add_development_dependency 'gsl-nmatrix', '~> 1.17.0'
end
