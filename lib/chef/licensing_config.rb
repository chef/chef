require "chef-licensing"
require_relative "log"

class Chef
  class LicensingConfig
    # These are the licensing entitlement IDs for the various Chef products
    INFRA_ENTITLEMENT_ID = "a5213d76-181f-4924-adba-4b7ed2b098b5".freeze       # Chef Infra Client
    COMPLIANCE_ENTITLEMENT_ID = "3ff52c37-e41f-4f6c-ad4d-365192205968".freeze  # InSpec's entitlement ID
    WORKSTATION_ENTITLEMENT_ID = "x6f3bc76-a94f-4b6c-bc97-4b7ed2b045c0".freeze # Chef-Workstation's entitlement ID
  end
end

ChefLicensing.configure do |config|
  config.chef_product_name = "Infra"
  config.chef_entitlement_id = Chef::LicensingConfig::INFRA_ENTITLEMENT_ID
  config.chef_executable_name = "chef-client"
  config.license_server_url = "https://services.chef.io/licensing"
  config.logger = Chef::Log
  config.license_add_command = "--license-add"
end
