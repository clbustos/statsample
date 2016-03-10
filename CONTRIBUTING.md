# Contributing guide

## Installing statsample development dependencies

Keep in mind that either nmatrix OR rb-gsl are NOT NECESSARY for using statsample. They are just required for an optional speed up. 

Statsample also works with [rb-gsl](https://github.com/sciruby/rb-gsl).

Install dependencies:

  `bundle install`

And run the test suite (should be all green):

  `bundle exec rake test`

If you have problems installing nmatrix, please consult the [nmatrix installation wiki](https://github.com/SciRuby/nmatrix/wiki/Installation) or the [mailing list](https://groups.google.com/forum/#!forum/sciruby-dev).