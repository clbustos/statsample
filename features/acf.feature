Feature: ACF

  As a statistician
  So that I can evaluate autocorrelation of a series
  I want to evaluate acf

Background: a timeseries

  Given the following values in a timeseries:
    | timeseries |
    | 10  20  30  40  50  60  70  80  90  100 |
    | 110 120 130 140 150 160 170 180 190 200 |

Scenario: cross-check acf for 10 lags
  When I provide 10 lags for acf
  And I calculate acf
  Then I should get 11 values in resultant acf
  And I should see "1.0, 0.85, 0.7015037593984963, 0.556015037593985, 0.4150375939849624, 0.2800751879699248, 0.15263157894736842, 0.034210526315789476, -0.07368421052631578, -0.16954887218045114, -0.2518796992481203" as complete series 

Scenario: cross-check acf for 5 lags
  When I provide 5 lags for acf
  And I calculate acf
  Then I should get 6 values in resultant acf
  And I should see "1.0, 0.85, 0.7015037593984963, 0.556015037593985, 0.4150375939849624, 0.2800751879699248" as complete series

Scenario: first value should be 1.0
  When I provide 2 lags for acf
  And I calculate acf
  Then I should get 3 values in resultant acf
  And I should see 1.0 as first value

