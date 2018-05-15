require "chef/chef_fs/data_handler/data_handler_base"

class Chef
  module ChefFS
    module DataHandler
      class ContainerDataHandler < DataHandlerBase
        def normalize(container, entry)
          normalize_hash(container, {
            "containername" => remove_dot_json(entry.name),
            "containerpath" => remove_dot_json(entry.name),
          })
        end

        def preserve_key?(key)
          key == "containername"
        end

        # Verify that the JSON hash for this type has a key that matches its name.
        #
        # @param object [Object] JSON hash of the object
        # @param entry [Chef::ChefFS::FileSystem::BaseFSObject] filesystem object we are verifying
        # @yield  [s] callback to handle errors
        # @yieldparam [s<string>] error message
        def verify_integrity(object, entry)
          base_name = remove_dot_json(entry.name)
          if object["containername"] != base_name
            yield("Name in #{entry.path_for_printing} must be '#{base_name}' (is '#{object['containername']}')")
          end
        end

        # There is no chef_class for users, nor does to_ruby work.
      end
    end
  end
end
