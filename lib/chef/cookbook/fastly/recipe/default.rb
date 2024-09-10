#recipe to include the Fastly configuration

require 'fastly'

Fastly.configure do |config|
  config.api_token = '<FASTLY_API_TOKEN>'
end

# Create a backend
api_instance = Fastly::BackendApi.new
backend_opts = {
  service_id: '<SERVICE_ID>',  # Replace with  Fastly service ID
  version_id: 1,                   # Replace with the appropriate version ID
  name: 'my_backend',              # Name of the backend
  address: 'example.com',          # Address of the backend
  port: 80,                        # Port number
  ssl: false                       # Set to true if using SSL
}

begin
  result = api_instance.create_backend(backend_opts)
  Chef::Log.info("Backend created: #{result}")
rescue Fastly::ApiError => e
  Chef::Log.error("Failed to create backend: #{e}")
end

fastly_endpoint 'my_service' do
  version_id 56
  name 'my_endpoint'
  action :create
end
