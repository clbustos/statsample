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
  # See documentation of each class to use it
  module Factor
    # Anti-image covariance matrix.
    # Useful for inspection of desireability of data for factor analysis.
    # According to Dziuban  & Shirkey (1974, p.359): 
    #   "If this matrix does not exhibit many zero off-diagonal elements,
    #   the investigator has evidence that the correlation
    #   matrix is not appropriate for factor analysis."
    # 
    def self.anti_image_covariance_matrix(matrix)
      s2=Matrix.diag(*(matrix.inverse.diagonal)).inverse
      aicm=(s2)*matrix.inverse*(s2)
      aicm.extend(Statsample::CovariateMatrix)
    end
    def self.anti_image_correlation_matrix(matrix)
      s=Matrix.diag(*(matrix.inverse.diagonal)).sqrt.inverse
      aicm=s*matrix.inverse*s
      aicm.extend(Statsample::CovariateMatrix)

    end
      
    # Kaiser-Meyer-Olkin measure of sampling adequacy
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
  end
end
