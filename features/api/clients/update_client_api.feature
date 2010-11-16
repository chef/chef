@api @api_clients @clients_update
Feature: Update a client
  In order to keep my client data up-to-date
  As a Developer
  I want to update my client via the API 

  Scenario: Update a client 
    Given I am an administrator
      And a 'client' named 'isis' exists
      And a 'client' named 'isis_update'
     When I 'PUT' the 'client' to the path '/clients/isis'
     Then the inflated responses key 'name' should match '^isis$'
      And the inflated responses key 'private_key' should match 'BEGIN RSA PRIVATE KEY'
      
  Scenario: Update a client with a wrong private key
    Given I am an administrator
      And a 'client' named 'isis' exists
      And a 'client' named 'isis_update'
     When I 'PUT' the 'client' to the path '/clients/isis' using a wrong private key
     Then I should get a '401 "Unauthorized"' exception

  Scenario: Update a client when you are not an admin
    Given I am a non-admin
      And a 'client' named 'isis' exists
      And a 'client' named 'isis_update'
     When I 'PUT' the 'client' to the path '/clients/isis'
     Then I should get a '403 "Forbidden"' exception
     
  @privilege_escalation @oss_only
  Scenario: Non-admin clients cannot update themselves
    Given I am a non-admin 
     When I edit the 'not_admin' client
      And I set 'admin' to true
      And I save the client
     Then I should get a '403 "Forbidden"' exception
  
  
  

