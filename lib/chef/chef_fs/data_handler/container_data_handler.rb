require 'chef/chef_fs/data_handler/data_handler_base'

class Chef
  module ChefFS
    module DataHandler
      class ContainerDataHandler < DataHandlerBase
        def normalize(container, entry)
          normalize_hash(container, {
            'containername' => remove_dot_json(entry.name),
            'containerpath' => remove_dot_json(entry.name)
          })
        end

        def preserve_key(key)
          return key == 'containername'
        end

        def verify_integrity(object, entry, &on_error)
          base_name = remove_dot_json(entry.name)
          if object['containername'] != base_name
            on_error.call("Name in #{entry.path_for_printing} must be '#{base_name}' (is '#{object['name']}')")
          end
        end

        # There is no chef_class for users, nor does to_ruby work.
      end
    end
  end
end
