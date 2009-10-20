@api @api_clients @clients_list
Feature: List clients via the REST API
  In order to know what clients exists programatically
  As a Developer
  I want to list all the clients

  Scenario: List clients when none have been created
    Given a 'registration' named 'bobo' exists
      And there are no clients 
     When I 'GET' the path '/clients' 
     Then the inflated response should be '3' items long 

  Scenario: List clients when one has been created
    Given a 'registration' named 'bobo' exists
    Given a 'client' named 'isis' exists
     When I 'GET' the path '/clients'
     Then the inflated responses key 'isis' should match '^http://.+/clients/isis$'

  Scenario: List clients when two have been created
    Given a 'registration' named 'bobo' exists
      And a 'client' named 'isis' exists
      And a 'client' named 'neurosis' exists
     When I 'GET' the path '/clients'
     Then the inflated responses key 'isis' should match '^http://.+/clients/isis$'
      And the inflated responses key 'neurosis' should match '^http://.+/clients/neurosis$'

  Scenario: List clients when none have been created with a wrong private key
    Given a 'registration' named 'bobo' exists
      And there are no clients 
     When I 'GET' the path '/clients' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: List clients when one has been created and you are not an admin
    Given a 'registration' named 'not_admin' exists
    Given a 'client' named 'isis' exists
     When I 'GET' the path '/clients'
     Then I should get a '401 "Unauthorized"' exception

