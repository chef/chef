Feature: Execute Commands 
  In order to utilize the plethora of useful command line utilities 
  As a Developer
  I want to execute commands from within chef 

  Scenario: Execute a command
    Given a validated node
      And it includes the recipe 'execute_commands'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'mastodon_rocks' should exist

  Scenario: Execute a command with more than 4k of output
    Given a validated node
      And it includes the recipe 'execute_commands::4k'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'execute-4k.txt' should exist

