@lwrp @cookbooks
Feature: Light-weight resources and providers

  @solo
  Scenario Outline: Chef solo handles light-weight resources and providers
    Given a local cookbook repository
     When I run chef-solo with the 'lwrp::<recipe>' recipe
     Then the run should exit '0'
      And 'stdout' should have '<message>'

    Examples:
      | recipe                                    | message                          |
      | default_everything                        | Default everything               |
      | non_default_provider                      | Non-default provider             |
      | non_default_resource                      | Non-default resource             |
      | overridden_resource_initialize            | Overridden initialize            |
      | overridden_provider_load_current_resource | Overridden load_current_resource |

  @client @api
  Scenario Outline: Chef client handles light-weight resources and providers
    Given a validated node
      And it includes the recipe 'lwrp::<recipe>'
     When I run the chef-client
     Then the run should exit '0'
      And 'stdout' should have '<message>'

    Examples:
      | recipe                                    | message                          |
      | default_everything                        | Default everything               |
      | non_default_provider                      | Non-default provider             |
      | non_default_resource                      | Non-default resource             |
      | overridden_resource_initialize            | Overridden initialize            |
      | overridden_provider_load_current_resource | Overridden load_current_resource |

