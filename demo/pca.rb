require File.dirname(__FILE__)+"/../lib/statsample"
require 'matrix_extension'
require 'reportbuilder'
require 'gsl'
ds=Statsample.load("/home/cdx/trabajo/sepade/pdie/2008_ntic/analisis_c1/tesis.ds")
ds2=ds['ac_gen'..'ac_db'].dup_only_valid

cm=Statsample::Bivariate.correlation_matrix(ds2)

pca=Statsample::Factor::PCA.new(cm, :m=>2)
rb=ReportBuilder.new()
rb.add(pca)

varimax=Statsample::Factor::Quartimax.new(pca.component_matrix.to_matrix)
varimax.iterate
rb.add(varimax.rotated)
rb.add(varimax.iterations)
rb.add(varimax.component_transformation_matrix)
rb.add(varimax.h2)
=begin
fa=Statsample::Factor::PrincipalAxis.new(cm, :m=>1)
rb=ReportBuilder.new()
rb.add(fa)

=end
puts rb.to_text



