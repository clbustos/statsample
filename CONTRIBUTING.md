# Contributing guide

## Installing statsample development dependencies

If you want to run the full test suite, you will need the latest unreleased nmatrix and gsl-nmatrix ruby gems. They will be released upstream soon but please follow this procdure for now.

Keep in mind that either nmatrix OR gsl-nmatrix are NOT NECESSARY for using statsample. They are just required for an optional speed up. 

Statsample also works with [rb-gsl](https://github.com/blackwinter/rb-gsl), though installing that will cause a problem if you have any nmatrix dependent code because narray and nmatrix have a namespace problem.

To install dependencies, execute the following commands:

  `export CPLUS_INCLUDE_PATH=/usr/include/atlas` 
  `export C_INCLUDE_PATH=/usr/include/atlas`
  `sudo apt-get update -qq`
  `sudo apt-get install -qq libatlas-base-dev`
  `sudo apt-get --purge remove liblapack-dev liblapack3 liblapack3gf`
  `sudo apt-get install -y libgsl0-dev r-base r-base-dev`
  `sudo Rscript -e "install.packages(c('Rserve','irr'),,'http://cran.us.r-project.org')"`

Then execute the .build.sh script to clone and install the latest nmatrix and gsl-nmatrix on your system:

  `./.build.sh`

Then finally install remaining dependencies:

  `bundle install`

And run the test suite (should be all green):

  `bundle exec rake test`

If you have problems installing nmatrix, please consult the [nmatrix installation wiki](https://github.com/SciRuby/nmatrix/wiki/Installation) or the [mailing list](https://groups.google.com/forum/#!forum/sciruby-dev).