require 'statsample'
require 'debugger'
include Statsample::TimeSeries

#all instance variable and cucumber DSL s DRYed up in step_definitions.rb
And /^I calculate acf$/ do
  @result = @timeseries.acf(@lags)
end

