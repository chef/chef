@api @cookbooks
Feature: Show a cookbooks attribute files via the REST API 
  In order to know what the details are for a cookbooks attribute files
  As a Developer
  I want to show the attribute files for a specific cookbook 
  
  Scenario: Show a cookbooks attribute files
    Given a 'registration' named 'bobo' exists
     When I 'GET' the path '/cookbooks/show_cookbook/attributes'
     Then the inflated response should match '^\[.+\]$' as json 

  Scenario: Show a missing cookbook 
    Given a 'registration' named 'bobo' exists
     When I 'GET' the path '/cookbooks/frabjabtasticaliciousmonkeyman/attributes'
     Then I should get a '404 "Not Found"' exception

  Scenario: Show a cookbooks attribute files with a wrong private key
    Given a 'registration' named 'bobo' exists
      When I 'GET' the path '/cookbooks/show_cookbook/attributes' using a wrong private key
      Then I should get a '401 "Unauthorized"' exception

