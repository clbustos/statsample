# Statsample

[![Build Status](https://travis-ci.org/SciRuby/statsample.svg?branch=master)](https://travis-ci.org/SciRuby/statsample)
[![Code Climate](https://codeclimate.com/github/SciRuby/statsample/badges/gpa.svg)](https://codeclimate.com/github/SciRuby/statsample)
[![Gem Version](https://badge.fury.io/rb/statsample.svg)](http://badge.fury.io/rb/statsample)

Homepage :: https://github.com/sciruby/statsample

# Installation

You should have a recent version of GSL and R (with the `irr` and `Rserve` libraries) installed. In Ubuntu:

```bash
$ sudo apt-get install libgs10-dev r-base r-base-dev
$ sudo Rscript -e "install.packages(c('Rserve', 'irr'))"
```

With these libraries in place, just install from rubygems:

```bash
$ [sudo] gem install statsample
```

On *nix, you should install statsample-optimization to retrieve gems gsl, statistics2 and a C extension to speed some methods.

```bash
$ [sudo] gem install statsample-optimization
```

If you need to work on Structural Equation Modeling, you could see +statsample-sem+. You need R with +sem+ or +OpenMx+ [http://openmx.psyc.virginia.edu/] libraries installed

```bash
$ [sudo] gem install statsample-sem
```

# Documentation

You can see the latest documentation in [rubydoc.info](http://www.rubydoc.info/github/sciruby/statsample/master).

# Description

A suite for basic and advanced statistics on Ruby. Tested on CRuby 1.9.3, 2.0.0 and 2.1.1. See `.travis.yml` for more information.

Include:
- Descriptive statistics: frequencies, median, mean, standard error, skew, kurtosis (and many others).
- Imports and exports datasets from and to Excel, CSV and plain text files.
- Correlations: Pearson's r, Spearman's rank correlation (rho), point biserial, tau a, tau b and  gamma.  Tetrachoric and Polychoric correlation provides by +statsample-bivariate-extension+ gem.
- Intra-class correlation
- Anova: generic and vector-based One-way ANOVA and Two-way ANOVA, with contrasts for One-way ANOVA.
- Tests: F, T, Levene, U-Mannwhitney.
- Regression: Simple, Multiple (OLS), Probit  and Logit
- Factorial Analysis: Extraction (PCA and Principal Axis), Rotation (Varimax, Equimax, Quartimax) and Parallel Analysis and Velicer's MAP test, for estimation of number of factors.
- Reliability analysis for simple scale and a DSL to easily analyze multiple scales using factor analysis and correlations, if you want it.
- Basic time series support
- Dominance Analysis, with multivariate dependent and bootstrap (Azen & Budescu)
- Sample calculation related formulas
- Structural Equation Modeling (SEM), using R libraries +sem+ and +OpenMx+
- Creates reports on text, html and rtf, using ReportBuilder gem
- Graphics: Histogram, Boxplot and Scatterplot

## Principles

- Software Design:
  - One module/class for each type of analysis
  - Options can be set as hash on initialize() or as setters methods
  - Clean API for interactive sessions
  - summary() returns all necessary informacion for interactive sessions
  - All statistical data available though methods on objects
  - All (important) methods should be tested. Better with random data.
- Statistical Design
  - Results are tested against text results, SPSS and R outputs.
  - Go beyond Null Hiphotesis Testing, using confidence intervals and effect sizes when possible
  - (When possible) All references for methods are documented, providing sensible information on documentation

# Features

- Classes for manipulation and storage of data:
  - Statsample::Vector: An extension of an array, with statistical methods like sum, mean and standard deviation
  - Statsample::Dataset: a group of Statsample::Vector, analog to a excel spreadsheet or a dataframe on R. The base of almost all operations on statsample.
  - Statsample::Multiset: multiple datasets with same fields and type of vectors
- Anova module provides generic Statsample::Anova::OneWay and vector based Statsample::Anova::OneWayWithVectors. Also you can create contrast using Statsample::Anova::Contrast
- Module Statsample::Bivariate provides covariance and pearson, spearman, point biserial, tau a, tau b, gamma, tetrachoric (see Bivariate::Tetrachoric) and polychoric (see Bivariate::Polychoric) correlations. Include methods to create correlation and covariance matrices
- Multiple types of regression.
  - Simple Regression :  Statsample::Regression::Simple
  - Multiple Regression: Statsample::Regression::Multiple
  - Logit Regression:    Statsample::Regression::Binomial::Logit
  - Probit Regression:    Statsample::Regression::Binomial::Probit
- Factorial Analysis algorithms on Statsample::Factor module.
  - Classes for Extraction of factors:
    - Statsample::Factor::PCA
    - Statsample::Factor::PrincipalAxis
  - Classes for Rotation of factors:
    - Statsample::Factor::Varimax
    - Statsample::Factor::Equimax
    - Statsample::Factor::Quartimax
  - Classes for calculation of factors to retain
    - Statsample::Factor::ParallelAnalysis performs Horn's 'parallel analysis' to a principal components analysis to adjust for sample bias in the retention of components.
    - Statsample::Factor::MAP performs Velicer's Minimum Average Partial (MAP) test, which retain components as long as the variance in the correlation matrix represents systematic variance.
- Dominance Analysis. Based on Budescu and Azen papers, dominance analysis is a method to analyze the relative importance of one predictor relative to another on multiple regression
  - Statsample::DominanceAnalysis class can report dominance analysis for a sample, using uni or multivariate dependent variables
  - Statsample::DominanceAnalysis::Bootstrap can execute bootstrap analysis to determine dominance stability, as recomended by  Azen & Budescu (2003) link[http://psycnet.apa.org/journals/met/8/2/129/].
- Module Statsample::Codification, to help to codify open questions
- Converters to import and export data:
  - Statsample::Database : Can create sql to create tables, read and insert data
  - Statsample::CSV : Read and write CSV files
  - Statsample::Excel : Read and write Excel files
  - Statsample::Mx    : Write Mx Files
  - Statsample::GGobi : Write Ggobi files
- Module Statsample::Crosstab provides function to create crosstab for categorical data
- Module Statsample::Reliability provides functions to analyze scales with psychometric methods.
  - Class Statsample::Reliability::ScaleAnalysis provides statistics like mean, standard deviation for a scale, Cronbach's alpha and standarized Cronbach's alpha, and for each item: mean, correlation with total scale, mean if deleted, Cronbach's alpha is deleted.
  - Class Statsample::Reliability::MultiScaleAnalysis provides a DSL to easily analyze reliability of multiple scales and retrieve correlation matrix and factor analysis of them.
  - Class Statsample::Reliability::ICC provides intra-class correlation, using Shrout & Fleiss(1979) and McGraw & Wong (1996) formulations.
- Module Statsample::SRS (Simple Random Sampling) provides a lot of functions to estimate standard error for several type of samples
- Module Statsample::Test provides several methods and classes to perform inferencial statistics
  - Statsample::Test::BartlettSphericity
  - Statsample::Test::ChiSquare
  - Statsample::Test::F
  - Statsample::Test::KolmogorovSmirnov (only D value)
  - Statsample::Test::Levene
  - Statsample::Test::UMannWhitney
  - Statsample::Test::T
  - Statsample::Test::WilcoxonSignedRank
- Module Graph provides several classes to create beautiful graphs using rubyvis
  - Statsample::Graph::Boxplot
  - Statsample::Graph::Histogram
  - Statsample::Graph::Scatterplot
- Gem <tt>bio-statsample-timeseries</tt> provides module Statsample::TimeSeries with support for time series, including ARIMA estimation using Kalman-Filter.
- Gem <tt>statsample-sem</tt> provides a DSL to R libraries +sem+ and +OpenMx+
- Gem <tt>statsample-glm</tt> provides you with GML method, to work with Logistic, Poisson and Gaussian regression ,using ML or IRWLS.
- Close integration with gem <tt>reportbuilder</tt>, to easily create reports on text, html and rtf formats.

# Usage

See the [examples folder](https://github.com/clbustos/statsample/tree/master/examples/) too.

## Boxplot

```ruby
require 'statsample'

ss_analysis(Statsample::Graph::Boxplot) do
  n = 30
  a = rnorm(n-1, 50, 10)
  b = rnorm(n, 30, 5)
  c = rnorm(n, 5, 1)
  a.push(2)
  boxplot(vectors: [a, b, c],
          width: 300,
          height: 300,
          groups: %w{first first second},
          minimum: 0)
end

Statsample::Analysis.run # Open svg file on *nix application defined
```

## Correlation matrix

```ruby
require 'statsample'
# Note R like generation of random gaussian variable
# and correlation matrix

ss_analysis("Statsample::Bivariate.correlation_matrix") do
  samples = 1000
  ds = data_frame(
    'a' => rnorm(samples),
    'b' => rnorm(samples),
    'c' => rnorm(samples),
    'd' => rnorm(samples))
  cm = cor(ds)
  summary(cm)
end

Statsample::Analysis.run_batch # Echo output to console
```

# Resources

- Source code on github :: http://github.com/sciruby/statsample
- Bug report and feature request :: http://github.com/sciruby/statsample/issues
- E-mailing list :: https://groups.google.com/forum/#!forum/sciruby-dev

# License

BSD-3 (See LICENSE.txt)

Could change between version, without previous warning. If you want a specific license, just choose the version that you need.
