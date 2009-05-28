@client @roles
Feature: Configure nodes based on their role 
  In order to easily configure similar systems
  As an Administrator
  I want to define and utilize roles

  Scenario: Apply a role to a node
    Given a validated node
      And it includes the role 'role_test'
     When I run the chef-client with '-l debug'
     Then the run should exit '0'
      And 'stdout' should have 'DEBUG: Loading Recipe roles'

