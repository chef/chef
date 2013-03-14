require 'chef/chef_fs/data_handler/data_handler_base'
require 'chef/api_client'

class Chef
  module ChefFS
    module DataHandler
      class GroupDataHandler < DataHandlerBase
        def normalize(group, entry)
          defaults = {
            'name' => remove_dot_json(entry.name),
            'groupname' => remove_dot_json(entry.name),
            'users' => [],
            'actors' => [],
            'clients' => [],
            'groups' => [],
          }
          if entry.org
            defaults['orgname'] = entry.org
          end
          super(group, defaults)
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
