Gem::Specification.new do |s|
  s.name               = 'statsample'
  s.version            = '1.1.0.2013'
  s.date               = '2013-04-28'
  s.summary            = 'StatSample - Ruby Statistical library'
  s.description        = "A suite for basic and advanced statistics on Ruby. Tested on Ruby 1.8.7 1.9.1, 1.9.2 and 1.9.3, JRuby 1.4(Ruby 1.8.7 compatible)."
  s.authors            = ["Claudio Bustos"]
  s.email              = ["clbustos@gmail.com"]
  s.executables        = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.files              = `git ls-files -- lib/*`.split("\n")
  s.extra_rdoc_files  += ['History.txt', 'Manifest.txt', 'README.md', 'references.txt']

  s.homepage           = "http://github.com/clbustos/statsample"
  s.require_path       = "lib"
  s.rubyforge_project  = "ruby-statsample"
  s.test_files         = `git ls-files -- {test}/*`.split("\n")

  DEPENDENCIES         = [{:gem => "spreadsheet", :version => "~> 0.8.5"}, {:gem => "reportbuilder", :version => "~> 1.4.2"},
   {:gem => "minimization", :version => "~> 0.2.1"}, {:gem => "fastercsv", :version => "~> 1.5.5"}, 
   {:gem => "dirty-memoize", :version => "~> 0.0.4"}, {:gem => "extendmatrix", :version => "~> 0.3.1"},
   {:gem => "statsample-bivariate-extension", :version => "~> 1.1.0"}, {:gem => "rserve-client", :version => "~> 0.3.0"},
   {:gem => "rubyvis", :version => "~> 0.5.2"}, {:gem => "gettext", :version => "~> 2.3.9"},
   {:gem => "mocha", :version => "~> 0.14.0"}, {:gem => "hoe-git", :version => "~> 1.5.0"},
   {:gem => "minitest", :version => "~> 5.0.5"}, {:gem => "shoulda", :version => "~> 3.5.0"},
  ]
  DEPENDENCIES.each do |dependency|
    s.add_dependency(dependency[:gem], dependency[:version])
  end
end
