require 'fastly'

Fastly.configure do |config|
  config.api_token = 'YOUR_FASTLY_API_TOKEN'
end

# Define your custom resource for creating the Fastly endpoint
class FastlyEndpointResource < Chef::Resource
  resource_name :fastly_endpoint

  property :service_id, String, name_property: true
  property :version_id, Integer
  property :name, String

  action :create do
    api_instance = Fastly::AclApi.new
    opts = {
      service_id: new_resource.service_id,
      version_id: new_resource.version_id,
      name: new_resource.name
    }

    begin
      result = api_instance.create_acl(opts)
      Chef::Log.info("Fastly endpoint created: #{result}")
    rescue Fastly::ApiError => e
      Chef::Log.error("Failed to create Fastly endpoint: #{e}")
      raise
    end
  end
end
