@api @cookbooks @show_cookbook
Feature: Show a cookbook via the REST API 
  In order to know what the details are for a cookbook 
  As a Developer
  I want to show the details for a specific cookbook 
  
  Scenario: Show a cookbook 
    Given a 'registration' named 'bobo' exists
     When I 'GET' the path '/cookbooks/show_cookbook'
     Then the inflated responses key 'name' should match 'show_cookbook'
     Then the inflated responses key 'files' should match '^\[.+\]$' as json
     Then the inflated responses key 'recipes' should match '^\[.+\]$' as json
     Then the inflated responses key 'metadata' should match '^\{.+\}$' as json
     Then the inflated responses key 'attributes' should match '^\[.+\]$' as json
     Then the inflated responses key 'libraries' should match '^\[.+\]$' as json
     Then the inflated responses key 'definitions' should match '^\[.+\]$' as json
     Then the inflated responses key 'templates' should match '^\[.+\]$' as json

  Scenario: Show a missing cookbook 
    Given a 'registration' named 'bobo' exists
     When I 'GET' the path '/cookbooks/frabnabjabtalistic'
     Then I should get a '404 "Not Found"' exception

  Scenario: Show a cookbook with a wrong private key
    Given a 'registration' named 'bobo' exists
     When I 'GET' the path '/cookbooks/show_cookbook' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception


