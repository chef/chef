@language @attribute_inclusion
Feature: Attribute Inclusion 
  In order to encapsulate functionality and re-use it
  As a developer
  I want to include an attribute file  from another one

  Scenario: Include an attribute directly
    Given a validated node
      And it includes the recipe 'attribute_include'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'mars_volta' should contain 'mars_volta is dope' only '1' time 

  Scenario: Include a default attribute file
    Given a validated node
      And it includes the recipe 'attribute_include_default'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'mars_volta' should contain 'mars_volta is dope' only '1' time 

