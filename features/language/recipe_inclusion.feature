@language @recipe_inclusion
Feature: Recipe Inclusion 
  In order to encapsulate functionality and re-use it
  As a developer
  I want to include a recipe from another one

  Scenario: Include a recipe directly
    Given a validated node
      And it includes the recipe 'recipe_include'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'fire_once' should contain 'mars_volta' only '1' time 

  Scenario: Include a recipe multipe times
    Given a validated node
      And it includes the recipe 'recipe_include'
      And it includes the recipe 'recipe_include::second'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'fire_once' should contain 'mars_volta' only '1' time

