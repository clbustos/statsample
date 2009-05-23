= rubyss

* http://code.google.com/p/ruby-statsample/

== DESCRIPTION:

This package allows to process files and databases for statistical purposes, with focus on validation, recodification and estimation of parameters for several types of samples (simple random, stratified and multistage sampling).

== FEATURES:

* Classes for Vector, Datasets (set of Vectors) and Multisets (multiple datasets with same fields and type of vectors), and multiple methods to manipulate them
* Module Codification, to help to codify open questions
* Converters to and from database and csv files, and to output Mx and GGobi files
* Module Correlation provides covariance and pearson, spearman, point biserial, tau a, tau b and gamma correlations. Include methods to create correlation and covariance matrices
* Module Crosstab provides function to create crosstab for categorical data
* Module HtmlReport provides methods to create a report for scale analysis and matrix correlation
* Regression module provides linear regression methods
* Reliability analysis provides functions to analyze scales. Class ItemAnalysis provides statistics like mean, standard deviation for a scale, alpha and standarized alpha, and for each item: mean, correlation with total scale, mean if deleted, alpha is deleted. With HtmlReport, graph the histogram of the scale and the Item Characteristic Curve for each item
* Module SRS (Simple Random Sampling) provides a lot of functions to estimate standard error for several type of samples
* Interfaces to gdchart, gnuplot and SVG::Graph 


== Example of use:

    # Read a CSV file, using '' and 'error' as missing values and ommiting 1 lines
    ds=RubySS::CSV.read('resultados_c1.csv',['','error'],1)
    
    # Create a new vector (column), calculating the mean of 13 vectors. Accept 1 missing values on one of the vectors
    
    indice_constructivismo_becker=ds.vector_mean(%w{fd_2_1 fd_2_2 fd_3_1 fd_3_2 fd_3_3},1)
    
    # Add the vector to the dataset
    
    ds.add_vector("ind_cons_becker",indice_constructivismo_becker)
    
    # Verify data. Vecto 'de_3_sex' must have values 'a' or 'b'. Dataset#verify returns and array with all errors
    
    t_sex=create_test("Sex must be a o b",'de_3_sex') {|v| v['de_3_sex']=="a" or v['de_3_sex']=="b")}
    
    p ds.verify(t_sexo)
    
    
    # Creates a new dataset, based on the names of vectors
    
    ds_software=ds.dup(%w{pe1n1 pe1n2 pe1n3 pe1n4 pe1n5 })
    
    # Creates an html report, add a correlation matrix with all the scale vectors and save the report into a file 
    hr=RubySS::HtmlReport.new(ds_software,"correlations")
    hr.add_correlation_matrix()
    hr.save("correlation_matrix.html")
    
    
    # Saves the new dataset
    RubySS::CSV.write(ds_software,"ds_software.csv",true)

== REQUIREMENTS:

Optional: 

* Plotting: gnuplot and rbgnuplot, SVG::Graph
* Advanced Statistical: gsl and rb-gsl

== INSTALL:

sudo gem install rubyss-VERSION.gem

== LICENSE:

GPL-2
