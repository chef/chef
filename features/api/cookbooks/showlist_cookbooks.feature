@api @cookbooks @show_cookbook
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

  @show_cookbook_negative
  Scenario: Show a cookbook with a wrong private key
    Given I am an administrator
     When I 'GET' the path '/cookbooks/show_cookbook' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  @list_cookbooks
  Scenario: List cookbooks with a wrong private key
    Given I am an administrator
     When I 'GET' the path '/cookbooks' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception
 
  @show_cookbook_negative
  Scenario: Listing versions for a non-existent cookbook should fail
    Given I am an administrator
    When I 'GET' the path '/cookbooks/non_existent'
    Then I should get a '404 "Not Found"' exception

