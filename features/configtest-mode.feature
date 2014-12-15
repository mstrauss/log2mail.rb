Feature: Configuration Examination
  In order verify correct configuration
  As a respnosible system administrator
  I want to see a configuration summary

  Scenario: Show configuration settings
    Given I use mode "configtest"
    And config "config_1"
    When log2mail is run
    Then the output should be:
      | File     | Pattern          | Recipient                   | Settings |
      | test.log | string pattern   | recipient@test.itstrauss.eu |          |
      | test.log | /regexp pattern/ | recipient@test.itstrauss.eu |          |
  Scenario: Show effective configuration settings
    Given I use mode "configtest"
    And config "config_1"
    And parameter "-e"
    When log2mail is run
    Then the output should be:
      | File     | Pattern          | Recipient                   | Effective Settings |
      | test.log | string pattern   | recipient@test.itstrauss.eu | fromaddr=log2mail  |
      | test.log | /regexp pattern/ | recipient@test.itstrauss.eu | fromaddr=log2mail  |
