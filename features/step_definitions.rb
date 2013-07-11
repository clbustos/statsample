require 'statsample'
require 'debugger'
include Statsample::TimeSeries

Given /^the following values in a timeseries:$/ do |series|
  arr = []
  series.hashes.each do |sequence|
    arr += sequence['timeseries'].split(' ').map(&:to_i).to_ts
  end
  @timeseries = arr.to_ts
end

When /^I provide (\d+) lags for pacf$/ do |lags|
  @lags = lags.to_i
end

When /^I provide (\w+) yule walker as method$/ do |method|
  @method = method
end

Then /^I should get (\w+) as resultant output$/ do |klass|
  @result = @timeseries.pacf(@lags, @method)
  assert_equal @result.class.to_s, klass
end

Then /^I should get (\w+) values in resultant pacf$/ do |values_count|
  assert_equal @result.size, values_count.to_i
  @timeseries
end

And /^I should see (\d+\.\d) as first value$/ do |first_value|
  assert_equal @result.first, first_value.to_f
end

And /^I should see \"(.+)\" as complete series$/ do |series|
  series = series.split(',').map(&:to_f)
  assert_equal @result, series
end

