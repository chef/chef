require 'chef/chef_fs/data_handler/data_handler_base'
require 'chef/api_client'

class Chef
  module ChefFS
    module DataHandler
      class ClientDataHandler < DataHandlerBase
        def normalize(client, entry)
          defaults = {
            'name' => remove_dot_json(entry.name),
            'clientname' => remove_dot_json(entry.name),
            'orgname' => entry.org,
            'admin' => false,
            'validator' => false,
            'chef_type' => 'client'
          }
          if entry.org
            defaults['orgname'] = entry.org
          end
          result = normalize_hash(client, defaults)
          # You can NOT send json_class, or it will fail
          result.delete('json_class')
          result
        end

        def preserve_key(key)
          return key == 'name'
        end

        def chef_class
          Chef::ApiClient
        end

        # There is no Ruby API for Chef::ApiClient
      end
    end
  end
end
