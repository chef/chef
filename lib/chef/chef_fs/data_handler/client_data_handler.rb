require 'chef/chef_fs/data_handler/data_handler_base'
require 'chef/api_client'

class Chef
  module ChefFS
    module DataHandler
      class ClientDataHandler < DataHandlerBase
        def normalize(client, name)
          super(client, {
            'name' => name,
            'admin' => false,
            'validator' => false,
            'json_class' => 'Chef::ApiClient',
            'chef_type' => 'client'
          })
        end

        def chef_class
          Chef::ApiClient
        end

        # There is no Ruby API for Chef::ApiClient
      end
    end
  end
end
