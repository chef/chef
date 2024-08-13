require "chef-licensing"

ChefLicensing.configure do |config|
  config.chef_product_name    = "Workstation"
  config.chef_entitlement_id  = "x6f3bc76-a94f-4b6c-bc97-4b7ed2b045c0"
  config.chef_executable_name = "Workstation"
  config.license_server_url   = "https://licensing-acceptance.chef.co/License"
end

