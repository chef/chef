require "chef-licensing"
require_relative "log"

ChefLicensing.configure do |config|
  config.chef_product_name = "Infra"
  config.chef_entitlement_id = "a5213d76-181f-4924-adba-4b7ed2b098b5"
  config.chef_executable_name = "chef-client"
  config.license_server_url = "https://services.chef.io/licensing"
  config.logger = Chef::Log
  config.license_add_command = "--license-add"
end
