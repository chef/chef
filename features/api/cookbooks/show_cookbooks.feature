@api @cookbooks @api_cookbooks_show
Feature: Show a cookbook via the REST API
  In order to know what the details are for a cookbook
  As a Developer
  I want to show the details for a specific cookbook

  @show_cookbook
  Scenario: Show a cookbook
    Given I am an administrator
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     Then I 'GET' the path '/cookbooks/testcookbook_valid/0.1.0'
     Then the inflated response should respond to 'cookbook_name' and match 'testcookbook_valid'
     Then the inflated response should respond to 'name' and match 'testcookbook_valid-0.1.0'
     Then the inflated response should respond to 'files' and match '^\[\]$' as json
     Then the inflated response should respond to 'root_files' and match '^\[.+\]$' as json
     Then the inflated response should respond to 'recipes' and match '^\[.+\]$' as json
     Then the inflated response should respond to 'metadata' and match '^\{.+\}$' as json
     Then the inflated response should respond to 'attributes' and match '^\[.+\]$' as json
     Then the inflated response should respond to 'libraries' and match '^\[\]$' as json
     Then the inflated response should respond to 'definitions' and match '^\[\]$' as json
     Then the inflated response should respond to 'templates' and match '^\[\]$' as json
     Then the inflated response should respond to 'resources' and match '^\[\]$' as json

  @CHEF-1607
  Scenario: Show the latest version of a cookbook
    Given I am an administrator
      And I upload multiple versions of the 'version_test' cookbook that do not lexically sort correctly
     When I 'GET' the path '/cookbooks/version_test/_latest'
     Then the inflated response should respond to 'version' and match '0.10.0'

  @show_cookbook_negative
  Scenario: Show a cookbook with a wrong private key
    Given I am an administrator
     When I 'GET' the path '/cookbooks/show_cookbook' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  @show_cookbook_negative
  Scenario: Listing versions for a non-existent cookbook should fail
    Given I am an administrator
    When I 'GET' the path '/cookbooks/non_existent'
    Then I should get a '404 "Not Found"' exception

  Scenario: Show all the available versions for a cookbook, sorted
    Given I am an administrator
      And I upload multiple versions of the 'version_test' cookbook that do not lexically sort correctly
     When I 'GET' the path '/cookbooks/version_test'
     Then the inflated responses key 'version_test' sub-key 'url' should match 'http://.+/cookbooks/version_test'
      And the inflated responses key 'version_test' sub-key 'versions' item '0' sub-key 'url' should match 'http://.+/cookbooks/version_test/(\d+.\d+.\d+)'
      And the inflated responses key 'version_test' sub-key 'versions' should be '3' items long
      And the inflated responses key 'version_test' sub-key 'versions' item '0' sub-key 'version' should equal '0.10.0'
      And the inflated responses key 'version_test' sub-key 'versions' item '1' sub-key 'version' should equal '0.9.7'
      And the inflated responses key 'version_test' sub-key 'versions' item '2' sub-key 'version' should equal '0.9.0'

  Scenario: Show the latest available version for a cookbook
    Given I am an administrator
      And I upload multiple versions of the 'version_test' cookbook that do not lexically sort correctly
     When I 'GET' the path '/cookbooks/version_test?num_versions=1'
     Then the inflated responses key 'version_test' sub-key 'url' should match 'http://.+/cookbooks/version_test'
      And the inflated responses key 'version_test' sub-key 'versions' item '0' sub-key 'url' should match 'http://.+/cookbooks/version_test/(\d+.\d+.\d+)'
      And the inflated responses key 'version_test' sub-key 'versions' should be '1' items long
      And the inflated responses key 'version_test' sub-key 'versions' item '0' sub-key 'version' should equal '0.10.0'

  Scenario: Show a given number available version for a cookbook, sorted by latest date
    Given I am an administrator
      And I upload multiple versions of the 'version_test' cookbook that do not lexically sort correctly
     When I 'GET' the path '/cookbooks/version_test?num_versions=2'
     Then the inflated responses key 'version_test' sub-key 'url' should match 'http://.+/cookbooks/version_test'
      And the inflated responses key 'version_test' sub-key 'versions' item '0' sub-key 'url' should match 'http://.+/cookbooks/version_test/(\d+.\d+.\d+)'
      And the inflated responses key 'version_test' sub-key 'versions' should be '2' items long
      And the inflated responses key 'version_test' sub-key 'versions' item '0' sub-key 'version' should equal '0.10.0'
      And the inflated responses key 'version_test' sub-key 'versions' item '1' sub-key 'version' should equal '0.9.7'
