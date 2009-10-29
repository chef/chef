@api @cookbooks @list_cookbooks
Feature: List cookbooks via the REST API
  In order to know what cookbooks are loaded on the Chef Server
  As a Developer
  I want to list all the cookbooks  

  Scenario: List cookbooks 
    Given a 'registration' named 'bobo' exists
     When I 'GET' the path '/cookbooks'
     Then the inflated responses key 'manage_files' should exist
      And the inflated responses key 'manage_files' should match 'http://[^/]+/cookbooks/manage_files'
      And the inflated responses key 'delayed_notifications' should exist
      And the inflated responses key 'delayed_notifications' should match 'http://[^/]+/cookbooks/delayed_notifications'

  Scenario: List cookbooks with a wrong private key
    Given a 'registration' named 'bobo' exists
     When I 'GET' the path '/cookbooks' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception


