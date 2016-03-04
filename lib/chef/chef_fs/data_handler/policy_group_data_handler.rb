require "chef/chef_fs/data_handler/data_handler_base"

class Chef
  module ChefFS
    module DataHandler
      class PolicyGroupDataHandler < DataHandlerBase

        def normalize(policy_group, entry)
          defaults = {
            "name" => remove_dot_json(entry.name),
            "policies" => {},
          }
          result = normalize_hash(policy_group, defaults)
          result.delete("uri") # not useful data
          result
        end

        # Verify that the JSON hash for this type has a key that matches its name.
        #
        # @param object [Object] JSON hash of the object
        # @param entry [Chef::ChefFS::FileSystem::BaseFSObject] filesystem object we are verifying
        # @yield  [s] callback to handle errors
        # @yieldparam [s<string>] error message
        def verify_integrity(object_data, entry)
          if object_data["policies"].empty?
            yield("Policy group #{object_data["name"]} does not have any policies in it.")
          end
        end

      end
    end
  end
end
