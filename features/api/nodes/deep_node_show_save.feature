@api @api_nodes @nodes_show @json_recusion @pl_538 @chef_1292
Feature: Save and show a node with deep structure via the API
  In order to verify that I can save and show very deep structure in a node object
  As a Developer
  I want to show the details for a specific node
  
  Scenario: Show a deeply nested node
    Given I am an administrator
      And a 'node' named 'really_deep_node' exists
     When I 'GET' the path '/nodes/really_deep_node'
     Then I should not get an exception
      And the inflated response should respond to 'name' with 'really_deep_node'
      And the 'deep_array' component has depth of '50' levels
      And the 'deep_hash' component has depth of '50' levels
