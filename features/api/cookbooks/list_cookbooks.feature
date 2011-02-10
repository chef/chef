@api @cookbooks @api_cookbooks_list

Feature: List cookbooks via the REST API
  In order to know what cookbooks are available
  As a developer
  I want to be able to list all cookbooks via the REST API

  Scenario Outline: List all cookbooks
    Given I am <user_type>
      And I upload multiple versions of the 'version_test' cookbook
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'version_test' sub-key 'url' should match 'http://.+/cookbooks/version_test'
      And the inflated responses key 'version_test' sub-key 'versions' item '0' sub-key 'url' should match 'http://.+/cookbooks/version_test/(\d+.\d+.\d+)'
      And the inflated responses key 'version_test' sub-key 'versions' item '0' sub-key 'version' should equal '0.2.0'
      And the inflated responses key 'version_test' sub-key 'versions' should be '1' items long
     When I 'GET' the path '/cookbooks?num_versions=2'
     Then the inflated responses key 'version_test' sub-key 'versions' should be '2' items long
      And the inflated responses key 'version_test' sub-key 'versions' item '0' sub-key 'version' should equal '0.2.0'
     When I 'GET' the path '/cookbooks?num_versions=-1'
     Then the inflated responses key 'version_test' sub-key 'versions' should be '1' items long
     When I 'GET' the path '/cookbooks?num_versions=invalid-input'
     Then the inflated responses key 'version_test' sub-key 'versions' should be '0' items long
     When I 'GET' the path '/cookbooks?num_versions=all'
     Then the inflated responses key 'version_test' sub-key 'versions' should be '3' items long

  Examples:
    | user_type        |
    | an administrator |
    | a non-admin      |

  Scenario Outline: List all cookbooks with the latest version
    Given I am <user_type>
      And I upload multiple versions of the 'version_test' cookbook
     When I 'GET' the path '/cookbooks/_latest'
      And the inflated responses key 'attribute_include' should match 'http://.+/cookbooks/attribute_include/0\.1\.0'
      And the inflated responses key 'deploy' should match 'http://.+/cookbooks/deploy/0\.0\.0'
      And the inflated responses key 'metadata' should match 'http://.+/cookbooks/metadata/1\.0\.0'
      And the inflated responses key 'version_test' should match 'http://.+/cookbooks/version_test/0\.2\.0'

  Examples:
    | user_type        |
    | an administrator |
    | a non-admin      |

  @CHEF-1607
  Scenario: List all cookbooks with the lastest version, when they cannot be lexically sorted
    Given I am an administrator
      And I upload multiple versions of the 'version_test' cookbook that do not lexically sort correctly
     When I 'GET' the path '/cookbooks/_latest'
      And the inflated responses key 'version_test' should match 'http://.+/cookbooks/version_test/0\.10\.0'

  Scenario: List cookbooks with a wrong private key
    Given I am an administrator
     When I 'GET' the path '/cookbooks' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception
