@client @attribute_settings

Feature: Set default, normal, and override attributes
  In order to easily configure similar systems
  As an Administrator
  I want to use different kinds of attributes

  Scenario: Set a default attribute in a cookbook attribute file
    Given I am an administrator
      And a validated node
      And it includes the recipe 'attribute_settings'
     When I run the chef-client
     Then the run should exit '0'
     Then a file named 'attribute_setting.txt' should contain 'came from recipe\[attribute_settings\] attributes'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from recipe\[attribute_settings\] attributes'

  Scenario: Set the default attribute in a environment
    Given I am an administrator
      And an 'environment' named 'default_attr_test' exists
      And a validated node in the 'default_attr_test' environment
      And it includes the recipe 'attribute_settings'
     When I run the chef-client with '-l debug'
     Then the run should exit '0'
      And a file named 'attribute_setting.txt' should contain 'came from environment default_attr_test default attributes'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from environment default_attr_test default attributes'

  Scenario: Set the default attribute in a role
    Given I am an administrator
      And an 'environment' named 'default_attr_test' exists
      And a 'role' named 'attribute_settings_default' exists
      And a validated node in the 'default_attr_test' environment
      And it includes the role 'attribute_settings_default'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'attribute_setting.txt' should contain 'came from role\[attribute_settings_default\] default attributes'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from role\[attribute_settings_default\] default attributes'

  Scenario: Set the default attribute in a recipe
    Given I am an administrator
      And an 'environment' named 'default_attr_test' exists
      And a 'role' named 'attribute_settings_default' exists
      And a validated node in the 'default_attr_test' environment
      And it includes the role 'attribute_settings_default'
      And it includes the recipe 'attribute_settings::default_in_recipe'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'attribute_setting.txt' should contain 'came from recipe\[attribute_settings::default_in_recipe\]'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from recipe\[attribute_settings::default_in_recipe\]'

  Scenario: Set a normal attribute in a cookbook attribute file
    Given I am an administrator
      And an 'environment' named 'default_attr_test' exists
      And a validated node in the 'default_attr_test' environment
      And a 'role' named 'attribute_settings_default' exists
      And it includes the role 'attribute_settings_default'
      And it includes the recipe 'attribute_settings::default_in_recipe'
      And it includes the recipe 'attribute_settings_normal'
     When I run the chef-client
     Then the run should exit '0'
     Then a file named 'attribute_setting.txt' should contain 'came from recipe\[attribute_settings_normal\] attributes'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from recipe\[attribute_settings_normal\] attributes'

  Scenario: Set a normal attribute in a cookbook recipe
    Given I am an administrator
      And an 'environment' named 'default_attr_test' exists
      And a validated node in the 'default_attr_test' environment
      And a 'role' named 'attribute_settings_default' exists
      And it includes the role 'attribute_settings_default'
      And it includes the recipe 'attribute_settings::default_in_recipe'
      And it includes the recipe 'attribute_settings_normal::normal_in_recipe'
     When I run the chef-client
     Then the run should exit '0'
     Then a file named 'attribute_setting.txt' should contain 'came from recipe\[attribute_settings_normal::normal_in_recipe\]'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from recipe\[attribute_settings_normal::normal_in_recipe\]'

  Scenario: Set an override attribute in a cookbook attribute file
    Given I am an administrator
      And an 'environment' named 'default_attr_test' exists
      And a validated node in the 'default_attr_test' environment
      And a 'role' named 'attribute_settings_default' exists
      And it includes the role 'attribute_settings_default'
      And it includes the recipe 'attribute_settings::default_in_recipe'
      And it includes the recipe 'attribute_settings_normal::normal_in_recipe'
      And it includes the recipe 'attribute_settings_override'
     When I run the chef-client
     Then the run should exit '0'
     Then a file named 'attribute_setting.txt' should contain 'came from recipe\[attribute_settings_override\] override attributes'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from recipe\[attribute_settings_override\] override attributes'

  Scenario: Set the override attribute in a role
    Given I am an administrator
      And a 'role' named 'attribute_settings_default' exists
      And a 'role' named 'attribute_settings_override' exists
      And an 'environment' named 'default_attr_test' exists
      And a validated node in the 'default_attr_test' environment
      And it includes the role 'attribute_settings_default'
      And it includes the recipe 'attribute_settings::default_in_recipe'
      And it includes the recipe 'attribute_settings_normal::normal_in_recipe'
      And it includes the recipe 'attribute_settings_override'
      And it includes the role 'attribute_settings_override'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'attribute_setting.txt' should contain 'came from role\[attribute_settings_override\] override attributes'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from role\[attribute_settings_override\] override attributes'

 Scenario: Set the override attribute in a environment
   Given I am an administrator
     And an 'environment' named 'cucumber' exists
     And a 'role' named 'attribute_settings_default' exists
     And a 'role' named 'attribute_settings_override' exists
     And a validated node in the 'cucumber' environment
     And it includes the role 'attribute_settings_default'
     And it includes the recipe 'attribute_settings::default_in_recipe'
     And it includes the recipe 'attribute_settings_normal::normal_in_recipe'
     And it includes the recipe 'attribute_settings_override'
     And it includes the role 'attribute_settings_override'
    When I run the chef-client with '-l debug'
    Then the run should exit '0'
     And a file named 'attribute_setting.txt' should contain 'came from environment cucumber override attributes'
    When the node is retrieved from the API
    Then the inflated responses key 'attribute_priority_was' should match 'came from environment cucumber override attributes'

  Scenario: Set the override attribute in a recipe
    Given I am an administrator
      And an 'environment' named 'cucumber' exists
      And a 'role' named 'attribute_settings_default' exists
      And a 'role' named 'attribute_settings_override' exists
      And a validated node in the 'cucumber' environment
      And it includes the role 'attribute_settings_default'
      And it includes the recipe 'attribute_settings::default_in_recipe'
      And it includes the recipe 'attribute_settings_normal::normal_in_recipe'
      And it includes the recipe 'attribute_settings_override'
      And it includes the role 'attribute_settings_override'
      And it includes the recipe 'attribute_settings_override::override_in_recipe'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'attribute_setting.txt' should contain 'came from recipe\[attribute_settings_override::override_in_recipe\]'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from recipe\[attribute_settings_override::override_in_recipe\]'

  Scenario: Data is removed from override attribute in a recipe
    Given I am an administrator
      And an 'environment' named 'cucumber' exists
      And a 'role' named 'attribute_settings_override' exists
      And a validated node in the 'cucumber' environment
      And it includes the role 'attribute_settings_override'
     When I run the chef-client
     Then the run should exit '0'
     And a file named 'attribute_setting.txt' should contain 'came from environment cucumber override attributes'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from environment cucumber override attributes'
    Given it includes no recipes
      And it includes the recipe 'integration_setup'
      And it includes the recipe 'no_attributes'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'attribute_setting.txt' should contain 'snakes'


  # Test that attributes from JSON are applied before attribute files are applied.
  @chef1286
  Scenario: Attributes from JSON files are normal attributes applied before attribute files
    Given I am an administrator
      And a validated node
      And it includes the recipe 'attribute_settings_normal'
     When I run the chef-client with json attributes
     Then the run should exit '0'
     Then a file named 'attribute_setting.txt' should contain 'came from recipe\[attribute_settings_normal\] attributes'
     When the node is retrieved from the API
     Then the inflated responses key 'attribute_priority_was' should match 'came from recipe\[attribute_settings_normal\] attributes'

  @chef1286
  Scenario: Attributes from JSON files have higher precedence than defaults
     Given a 'role' named 'attribute_settings_default' exists
       And a 'role' named 'attribute_settings_override' exists
       And a validated node
       And it includes the role 'attribute_settings_default'
       And it includes the recipe 'attribute_settings::default_in_recipe'
      When I run the chef-client with json attributes
      Then the run should exit '0'
      Then a file named 'attribute_setting.txt' should contain 'from_json_file'
      When the node is retrieved from the API
      Then the inflated responses key 'attribute_priority_was' should match 'from_json_file'

