require File.dirname(__FILE__)+"/../lib/statsample"
ds=Statsample::PlainText.read(File.dirname(__FILE__)+"/../data/tetmat_test.txt", %w{a b c d e})
puts Statsample::SPSS.tetrachoric_correlation_matrix(ds)
