Feature: PACF

  As a statistician
  So that I can quickly evaluate partial autocorrelation of a series
  I want to evaluate pacf

Background: a timeseries

  Given the following values in a timeseries:
    | timeseries |
    | 10  20  30  40  50  60  70  80  90  100 |
    | 110 120 130 140 150 160 170 180 190 200 |

Scenario: check pacf for 10 lags with unbiased
  When I provide 10 lags for pacf
  When I provide yw yule walker as method
  Then I should get Array as resultant output
  Then I should get 11 values in resultant pacf

Scenario: check pacf for 5 lags with mle
  When I provide 5 lags for pacf
  When I provide mle yule walker as method
  Then I should get Array as resultant output
  Then I should get 6 values in resultant pacf

Scenario: check first value of pacf
  When I provide 5 lags for pacf
  When I provide yw yule walker as method
  Then I should get Array as resultant output
  And I should see 1.0 as first value

Scenario: check all values in pacf for 5 lags with mle
  When I provide 5 lags for pacf
  When I provide mle yule walker as method
  Then I should get Array as resultant output
  And I should see "1.0, 0.85, -0.07566212829370711, -0.07635069706072706, -0.07698628638512295, -0.07747034005560738" as complete series 

Scenario: check all values in pacf for 5 lags with unbiased
  When I provide 5 lags for pacf
  When I provide yw yule walker as method
  Then I should get Array as resultant output
  And I should see "1.0, 0.8947368421052632, -0.10582010582010604, -0.11350188273265083, -0.12357534824820737, -0.13686534216335522" as complete series 
