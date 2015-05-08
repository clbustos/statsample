require 'statsample/factor/rotation'
require 'statsample/factor/pca'
require 'statsample/factor/principalaxis'
require 'statsample/factor/parallelanalysis'
require 'statsample/factor/map'

module Statsample
  # Factor Analysis toolbox.
  # * Classes for Extraction of factors: 
  #   * Statsample::Factor::PCA
  #   * Statsample::Factor::PrincipalAxis
  # * Classes for Rotation of factors: 
  #   * Statsample::Factor::Varimax
  #   * Statsample::Factor::Equimax
  #   * Statsample::Factor::Quartimax
  # * Classes for determining the number of components
  #   * Statsample::Factor::MAP
  #   * Statsample::Factor::ParallelAnalysis
  #
  # About number of components, O'Connor(2000) said:
  #  The two procedures [PA and MAP ] complement each other nicely,
  #  in that the MAP tends to err (when it does err) in the direction
  #  of underextraction, whereas parallel analysis tends to err
  #  (when it does err) in the direction of overextraction.
  #  Optimal decisions are thus likely to be made after considering
  #  the results of both analytic procedures. (p.10)

  module Factor
    # Anti-image covariance matrix.
    # Useful for inspection of desireability of data for factor analysis.
    # According to Dziuban  & Shirkey (1974, p.359): 
    #   "If this matrix does not exhibit many zero off-diagonal elements,
    #   the investigator has evidence that the correlation
    #   matrix is not appropriate for factor analysis."
    # 
    def self.anti_image_covariance_matrix(matrix)
      s2=Matrix.diagonal(*(matrix.inverse.diagonal)).inverse
      aicm=(s2)*matrix.inverse*(s2)
      aicm.extend(Statsample::CovariateMatrix)
      aicm.fields=matrix.fields if matrix.respond_to? :fields
      aicm
    end
    def self.anti_image_correlation_matrix(matrix)
      matrix=matrix.to_matrix
      s=Matrix.diagonal(*(matrix.inverse.diagonal)).sqrt.inverse
      aicm=s*matrix.inverse*s
      
      aicm.extend(Statsample::CovariateMatrix)
      aicm.fields=matrix.fields if matrix.respond_to? :fields
      aicm
    end
      
    # Kaiser-Meyer-Olkin measure of sampling adequacy for correlation matrix.
    # 
    # Kaiser's (1974, cited on Dziuban  & Shirkey, 1974) present calibration of the index is as follows :
    # * .90s—marvelous
    # * .80s— meritorious
    # * .70s—middling
    # * .60s—mediocre
    # * .50s—miserable
    # * .50 •—unacceptable
    def self.kmo(matrix)
      q=anti_image_correlation_matrix(matrix)
      n=matrix.row_size
      sum_r,sum_q=0,0
      n.times do |j|
        n.times do |k|
          if j!=k
            sum_r+=matrix[j,k]**2
            sum_q+=q[j,k]**2
          end
        end
      end
      sum_r.quo(sum_r+sum_q)
    end
    # Kaiser-Meyer-Olkin measure of sampling adequacy for one variable.
    # 
    def self.kmo_univariate(matrix, var)
      if var.is_a? String
        if matrix.respond_to? :fields
          j=matrix.fields.index(var)
          raise "Matrix doesn't have field #{var}" if j.nil?
        else
          raise "Matrix doesn't respond to fields"
        end
      else
        j=var
      end
      
      q=anti_image_correlation_matrix(matrix)
      n=matrix.row_size
      
      sum_r,sum_q=0,0
      
      n.times do |k|
        if j!=k
          sum_r+=matrix[j,k]**2
          sum_q+=q[j,k]**2
        end
      end
      sum_r.quo(sum_r+sum_q)
    end
  end
end
