@api @cookbooks @api_cookbooks_list

Feature: List cookbooks via the REST API
  In order to know what cookbooks are available
  As a developer
  I want to be able to list all cookbooks via the REST API

  Scenario Outline: List all cookbooks
    Given I am <user_type>
      And I upload multiple versions of the 'version_test' cookbook
     When I 'GET' the path '/cookbooks'
      And the inflated responses key 'attribute_include' should match 'http://.+/cookbooks/attribute_include/0\.1\.0'
      And the inflated responses key 'deploy' should match 'http://.+/cookbooks/deploy/0\.0\.0'
      And the inflated responses key 'metadata' should match 'http://.+/cookbooks/metadata/1\.0\.0'
      And the inflated responses key 'version_test' should match 'http://.+/cookbooks/version_test/0\.2\.0'

  Examples:
    | user_type        |
    | an administrator |
    | a non-admin      |

  Scenario: List cookbooks with a wrong private key
    Given I am an administrator
     When I 'GET' the path '/cookbooks' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception