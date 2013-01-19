require 'chef/chef_fs/data_handler/data_handler_base'
require 'chef/api_client'

class Chef
  module ChefFS
    module DataHandler
      class ClientDataHandler < DataHandlerBase
        def normalize(client, name)
          client['name'] ||= name
          client['admin'] ||= false
          client['public_key'] ||= PUBLIC_KEY
          client['validator'] ||= false
          client['json_class'] ||= "Chef::ApiClient"
          client['chef_type'] ||= "client"
          client
        end

        def chef_class
          Chef::ApiClient
        end

        # There is no Ruby API for Chef::ApiClient
      end
    end
  end
end
