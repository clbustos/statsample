= Statsample

http://ruby-statsample.rubyforge.org/


== FEATURES:

A suite for basic and advanced statistics. Includes:
* Descriptive statistics: frequencies, median, mean, standard error, skew, kurtosis (and many others).
* Imports and exports datasets from and to Excel, CSV and plain text files.
* Correlations: Pearson (r), Rho, Tetrachoric, Polychoric
* Regression: Simple, Multiple, Probit and Logit
* Factorial Analysis: Extraction (PCA and Principal Axis) and Rotation (Varimax and relatives)
* Dominance Analysis, with multivariate dependent and bootstrap (Azen & Budescu)
* Sample calculation related formulas

== DETAILED FEATURES:

* Factorial Analysis. Principal Component Analysis and Principal Axis extraction, with orthogonal rotations (Varimax, Equimax, Quartimax)
* Multiple Regression. Listwise analysis optimized with use of Alglib library. Pairwise analysis is executed on pure ruby with matrixes and reports same values as SPSS
* Module Bivariate provides covariance and pearson, spearman, point biserial, tau a, tau b, gamma, tetrachoric and polychoric correlation correlations. Include methods to create correlation (pearson and tetrachoric) and covariance matrices
* Regression module provides linear regression methods
* Dominance Analysis. Based on Budescu and Azen papers, <strong>DominanceAnalysis</strong> class can report dominance analysis for a sample, using uni or multivariate dependent variables and <strong>DominanceAnalysisBootstrap</strong> can execute bootstrap analysis to determine dominance stability, as recomended by  Azen & Budescu (2003) link[http://psycnet.apa.org/journals/met/8/2/129/]. 
* Classes for Vector, Datasets (set of Vectors) and Multisets (multiple datasets with same fields and type of vectors), and multiple methods to manipulate them
* Module Codification, to help to codify open questions
* Converters to and from database and csv files, and to output Mx and GGobi files
* Module Crosstab provides function to create crosstab for categorical data
* Reliability analysis provides functions to analyze scales. Class ItemAnalysis provides statistics like mean, standard deviation for a scale, Cronbach's alpha and standarized Cronbach's alpha, and for each item: mean, correlation with total scale, mean if deleted, Cronbach's alpha is deleted. With HtmlReport, graph the histogram of the scale and the Item Characteristic Curve for each item
* Module SRS (Simple Random Sampling) provides a lot of functions to estimate standard error for several type of samples
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
* Factorial analysis and polychorical correlation: gsl library and rb-gsl (http://rb-gsl.rubyforge.org/). You should install it using <tt>gem install gsl</tt>

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
