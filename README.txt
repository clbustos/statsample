= Statsample

http://ruby-statsample.rubyforge.org/


== DESCRIPTION:

A suite for basic and advanced statistics on Ruby. Tested on Ruby 1.8.7, 1.9.1, 1.9.2 (April, 2010) and JRuby 1.4 (Ruby 1.8.7 compatible) 

Includes:
* Descriptive statistics: frequencies, median, mean, standard error, skew, kurtosis (and many others).
* Imports and exports datasets from and to Excel, CSV and plain text files.
* Correlations: Pearson's r, Spearman's rank correlation (rho), Tetrachoric, Polychoric
* Tests: F (Anona One-Way), T, Levene, U-Mannwhitney.
* Regression: Simple, Multiple, Probit  and Logit
* Factorial Analysis: Extraction (PCA and Principal Axis) and Rotation (Varimax and relatives)
* Dominance Analysis, with multivariate dependent and bootstrap (Azen & Budescu)
* Sample calculation related formulas
* Creates reports on text, html and rtf, using ReportBuilder

== FEATURES:

* Classes for manipulation and storage of data:
  * Statsample::Vector: An extension of an array, with statistical methods like sum, mean and standard deviation
  * Statsample::Dataset: a group of Statsample::Vector, analog to a excel spreadsheet or a dataframe on R. The base of almost all operations on statsample. 
  * Statsample::Multiset: multiple datasets with same fields and type of vectors
* Module Statsample::Bivariate provides covariance and pearson, spearman, point biserial, tau a, tau b, gamma, tetrachoric (see Bivariate::Tetrachoric) and polychoric (see Bivariate::Polychoric) correlations. Include methods to create correlation and covariance matrices
* Multiple types of regression.
  * Simple Regression :  Statsample::Regression::Simple
  * Multiple Regression: Statsample::Regression::Multiple
  * Logit Regression:    Statsample::Regression::Binomial::Logit
  * Probit Regression:    Statsample::Regression::Binomial::Probit
* Factorial Analysis algorithms on Statsample::Factor module.
  * Classes for Extraction of factors: 
    * Statsample::Factor::PCA
    * Statsample::Factor::PrincipalAxis
  * Classes for Rotation of factors: 
    * Statsample::Factor::Varimax
    * Statsample::Factor::Equimax
    * Statsample::Factor::Quartimax
* Dominance Analysis. Based on Budescu and Azen papers, Statsample::DominanceAnalysis class can report dominance analysis for a sample, using uni or multivariate dependent variables and DominanceAnalysisBootstrap can execute bootstrap analysis to determine dominance stability, as recomended by  Azen & Budescu (2003) link[http://psycnet.apa.org/journals/met/8/2/129/]. 
* Module Statsample::Codification, to help to codify open questions
* Converters to import and export data:
  * Statsample::Database : Can create sql to create tables, read and insert data
  * Statsample::CSV : Read and write CSV files
  * Statsample::Excel : Read and write Excel files
  * Statsample::Mx    : Write Mx Files
  * Statsample::GGobi : Write Ggobi files
* Module Statsample::Crosstab provides function to create crosstab for categorical data
* Reliability analysis provides functions to analyze scales. Class ItemAnalysis provides statistics like mean, standard deviation for a scale, Cronbach's alpha and standarized Cronbach's alpha, and for each item: mean, correlation with total scale, mean if deleted, Cronbach's alpha is deleted. With HtmlReport, graph the histogram of the scale and the Item Characteristic Curve for each item
* Module Statsample::SRS (Simple Random Sampling) provides a lot of functions to estimate standard error for several type of samples
* Module Statsample::Test provides several methods and classes to perform inferencial statistics
  * Statsample::Test::Levene
  * Statsample::Test::UMannWhitney
  * Statsample::Test::T
* Interfaces to gdchart, gnuplot and SVG::Graph 


== Examples of use:

=== Correlation matrix

    require 'statsample'
    a=1000.times.collect {rand}.to_scale
    b=1000.times.collect {rand}.to_scale
    c=1000.times.collect {rand}.to_scale
    d=1000.times.collect {rand}.to_scale
    ds={'a'=>a,'b'=>b,'c'=>c,'d'=>d}.to_dataset
    cm=Statsample::Bivariate.correlation_matrix(ds)
    puts cm.summary

=== Tetrachoric correlation

    require 'statsample'
    a=40
    b=10
    c=20
    d=30
    tetra=Statsample::Bivariate::Tetrachoric.new(a,b,c,d)
    puts tetra.summary
    
=== Polychoric correlation

    require 'statsample'
    ct=Matrix[[58,52,1],[26,58,3],[8,12,9]]
    
    poly=Statsample::Bivariate::Polychoric.new(ct)
    puts poly.summary

== REQUIREMENTS:

Optional: 

* Plotting: gnuplot and rbgnuplot, SVG::Graph
* Factorial analysis and polychorical correlation(joint estimate and polychoric series): gsl library and rb-gsl (http://rb-gsl.rubyforge.org/). You should install it using <tt>gem install gsl</tt>. 

<b>Note</b>: Use gsl 1.12.109 or later.

== DOWNLOAD
* Gems and bugs report: http://rubyforge.org/projects/ruby-statsample/
* SVN and Wiki: http://code.google.com/p/ruby-statsample/

== INSTALL:

  sudo gem install ruby-statsample

For optimization on *nix env

  sudo gem install gsl ruby-statsample-optimization

Available setup.rb file

  sudo gem ruby setup.rb

== LICENSE:

GPL-2 (See LICENSE.txt)
