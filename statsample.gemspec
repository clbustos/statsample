# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'statsample/version'

Gem::Specification.new do |spec|
  spec.name          = 'statsample'
  spec.version       = Statsample::VERSION
  spec.summary       = "Stats library"
  spec.authors       = ["Claudio Bustos", "Justin Gordon", "Russell Smith"]
  spec.homepage      = 'https://github.com/clbustos/statsample'
  spec.license       = "MIT"
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rdoc'
  spec.add_development_dependency 'mocha', '0.14.0' #:require=>'mocha/setup'
  spec.add_development_dependency 'shoulda', '3.5.0'
  spec.add_development_dependency 'shoulda-matchers', '2.2.0'

  spec.add_dependency 'hoe'
  spec.add_dependency 'reportbuilder'
  spec.add_dependency 'dirty-memoize'
  spec.add_dependency 'distribution'
  spec.add_dependency 'extendmatrix'
  spec.add_dependency 'minimization'
  spec.add_dependency 'rserve-client'
  spec.add_dependency 'rubyvis'
  spec.add_dependency 'spreadsheet'
  spec.add_dependency 'rb-gsl'
end
