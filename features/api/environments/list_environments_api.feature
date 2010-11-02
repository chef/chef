@api @api_environments @environments_list
Feature: List environments via the REST API
  In order to know what environments exist programatically
  As a developer
  I want to list all the environments via the REST API

  Scenario Outline: List environments when none have been created
    Given I am <user_type>
      And there are no environments
     When I 'GET' the path '/environments'
     Then the inflated response should be '1' items long
     Then the inflated responses key '_default' should match 'http://.+/environments/_default'

    Examples:
      | user_type        |
      | an administrator |
      | a non-admin      |

  Scenario Outline: List the environments when one has been created
    Given I am <user_type>
      And an 'environment' named 'cucumber' exists
     When I 'GET' the path '/environments'
     Then the inflated responses key 'cucumber' should match 'http://.+/environments/cucumber'

    Examples:
      | user_type        |
      | an administrator |
      | a non-admin      |

  Scenario Outline: List the environments when two have been created
    Given I am <user_type>
      And an 'environment' named 'cucumber' exists
      And an 'environment' named 'production' exists
     When I 'GET' the path '/environments'
     Then the inflated response should be '3' items long
      And the inflated responses key 'cucumber' should match 'http://.+/environments/cucumber'
      And the inflated responses key 'production' should match 'http://.+/environments/production'

    Examples:
      | user_type        |
      | an administrator |
      | a non-admin      |

  Scenario Outline: List environments with a wrong private key
    Given I am <user_type>
     When I 'GET' the path '/environments' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

    Examples:
      | user_type        |
      | an administrator |
      | a non-admin      |
