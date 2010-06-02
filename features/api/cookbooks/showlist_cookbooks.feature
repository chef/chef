@api @cookbooks @show_cookbook
Feature: Show a cookbook via the REST API 
  In order to know what the details are for a cookbook 
  As a Developer
  I want to show the details for a specific cookbook 
  
  @show_cookbook
  Scenario: Show a cookbook 
    Given a 'registration' named 'bobo' exists
     When I fully upload a sandboxed cookbook named 'testcookbook_valid' versioned '0.1.0' with 'testcookbook_valid'
     Then I 'GET' the path '/cookbooks/testcookbook_valid/0.1.0'
     Then I call to_hash on the inflated response
     Then the inflated responses key 'name' should match 'testcookbook_valid'
     Then the inflated responses key 'files' should match '^\[.+\]$' as json
     Then the inflated responses key 'recipes' should match '^\[.+\]$' as json
     Then the inflated responses key 'metadata' should match '^\{.+\}$' as json
     Then the inflated responses key 'attributes' should match '^\[.+\]$' as json
     Then the inflated responses key 'libraries' should match '^\[.+\]$' as json
     Then the inflated responses key 'definitions' should match '^\[.+\]$' as json
     Then the inflated responses key 'templates' should match '^\[.+\]$' as json

  @show_cookbook_negative
  Scenario: Show a cookbook with a wrong private key
    Given a 'registration' named 'bobo' exists
     When I 'GET' the path '/cookbooks/show_cookbook' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  @list_cookbooks
  Scenario: List cookbooks with a wrong private key
    Given a 'registration' named 'bobo' exists
     When I 'GET' the path '/cookbooks' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception
 
  @show_cookbook_negative
  Scenario: Listing versions for a non-existent cookbook should fail
    Given a 'registration' named 'bobo' exists
    When I 'GET' the path '/cookbooks/non_existent'
    Then I should get a '404 "Not Found"' exception

