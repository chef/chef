@lwrp @cookbooks
Feature: Light-weight resources and providers

  @solo @lwrp_solo
  Scenario Outline: Chef solo handles light-weight resources and providers
    Given a local cookbook repository
     When I run chef-solo with the 'lwrp::<recipe>' recipe
     Then the run should exit '0'
      And 'stdout' should have '<message>'

    Examples:
      | recipe                                    | message                                                                          |
      | default_everything                        | Default everything                                                               |
      | non_default_provider                      | Non-default provider                                                             |
      | non_default_resource                      | Non-default resource                                                             |
      | overridden_resource_initialize            | Overridden initialize                                                            |
      | overridden_provider_load_current_resource | Overridden load_current_resource                                                 |
      | provider_is_a_string                      | Provider is a string                                                             |
      | provider_is_a_symbol                      | Provider is a symbol                                                             |
      | provider_is_a_class                       | Provider is a class                                                              |
      | provider_is_omitted                       | P=Chef::Provider::LwrpProviderIsOmitted, R=Chef::Resource::LwrpProviderIsOmitted |

  @solo @lwrp_solo
  Scenario: Chef solo properly handles providers that invoke resources in their action definitions
    Given a local cookbook repository
     When I run chef-solo with the 'lwrp::provider_invokes_resource' recipe
     Then the run should exit '0'
      And a file named 'lwrp_touch_file.txt' should exist

  @client @lwrp_api
  Scenario Outline: Chef-client handles light-weight resources and providers
    Given a validated node with an empty runlist
      And it includes the recipe 'lwrp::<recipe>'
     When I run the chef-client
     Then the run should exit '0'
      And 'stdout' should have '<message>'

    Examples:
      | recipe                                    | message                                                                          |
      | default_everything                        | Default everything                                                               |
      | non_default_provider                      | Non-default provider                                                             |
      | non_default_resource                      | Non-default resource                                                             |
      | overridden_resource_initialize            | Overridden initialize                                                            |
      | overridden_provider_load_current_resource | Overridden load_current_resource                                                 |
      | provider_is_a_string                      | Provider is a string                                                             |
      | provider_is_a_symbol                      | Provider is a symbol                                                             |
      | provider_is_a_class                       | Provider is a class                                                              |
      | provider_is_omitted                       | P=Chef::Provider::LwrpProviderIsOmitted, R=Chef::Resource::LwrpProviderIsOmitted |

  @client @lwrp_api
  Scenario: Chef-client properly handles providers that invoke resources in their action definitions
    Given a validated node
      And it includes the recipe 'lwrp::provider_invokes_resource'
     When I run the chef-client
     Then the run should exit '0'
      And a file named 'lwrp_touch_file.txt' should exist

