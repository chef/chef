require 'chef/chef_fs/data_handler/data_handler_base'

class Chef
  module ChefFS
    module DataHandler
      class ContainerDataHandler < DataHandlerBase
        def normalize(user, entry)
          super(user, {
            'containername' => remove_dot_json(entry.name),
            'containerpath' => remove_dot_json(entry.name)
          })
        end

        def preserve_key(key)
          return key == 'containername'
        end

        # There is no chef_class for users, nor does to_ruby work.
      end
    end
  end
end
