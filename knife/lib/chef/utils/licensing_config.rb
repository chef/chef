require "chef-licensing"

ChefLicensing.configure do |config|
  config.chef_product_name    = "Knife"
  config.chef_entitlement_id  = "x6f3bc76-a94f-4b6c-bc97-4b7ed2b045c0"
  config.chef_executable_name = "knife"
  config.license_server_url   = "https://services.chef.io/licensing"
end

