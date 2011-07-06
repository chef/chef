@client @roles @client_roles
Feature: Configure nodes based on their role
  In order to easily configure similar systems
  As an Administrator
  I want to define and utilize roles

  Scenario: Apply a role to a node
    Given I am an administrator
      And a validated node
      And it includes the role 'role_test'
      And a 'role' named 'role_test' exists
     When I run the chef-client with '-l debug'
     Then the run should exit '0'
      And 'stdout' should have 'DEBUG: Loading Recipe roles'
      And a file named 'role_test_reason.txt' should contain 'unbalancing'
      And a file named 'role_test_ossining.txt' should contain 'whatever'
      And a file named 'role_test_ruby_version.txt' should contain '1.\d+.\d+'

  Scenario: Apply a role with multiple environment specific run_lists to a node
    Given I am an administrator
      And an 'environment' named 'cucumber' exists
      And a validated node in the 'cucumber' environment
      And it includes the role 'role_env_test'
      And a 'role' named 'role_env_test' exists
     When I run the chef-client with '-l debug'
     Then the run should exit '0'
      And 'stdout' should have 'DEBUG: Loading Recipe roles'
      And a file named 'role_env_test_reason.txt' should contain 'unbalancing'
      And a file named 'role_env_test_ossining.txt' should contain 'whatever'
      And a file named 'role_env_test_ruby_version.txt' should contain '1.\d+.\d+'
