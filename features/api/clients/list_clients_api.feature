@api @api_clients @clients_list
Feature: List clients via the REST API
  In order to know what clients exists programatically
  As a Developer
  I want to list all the clients

  Scenario: List clients when one has been created
    Given I am an administrator
    Given a 'client' named 'isis' exists
     When I 'GET' the path '/clients'
     Then the inflated responses key 'isis' should match '^http://.+/clients/isis$'

  Scenario: List clients when two have been created
    Given I am an administrator
      And a 'client' named 'isis' exists
      And a 'client' named 'neurosis' exists
     When I 'GET' the path '/clients'
     Then the inflated responses key 'isis' should match '^http://.+/clients/isis$'
      And the inflated responses key 'neurosis' should match '^http://.+/clients/neurosis$'

  Scenario: List clients when none have been created with a wrong private key
    Given I am an administrator
      And there are no clients
     When I 'GET' the path '/clients' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  @oss_only
  Scenario: List clients when one has been created and you are not an admin
    Given I am a non-admin
    Given a 'client' named 'isis' exists
     When I 'GET' the path '/clients'
     Then I should get a '403 "Forbidden"' exception

