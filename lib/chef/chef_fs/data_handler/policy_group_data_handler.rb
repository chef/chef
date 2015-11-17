require 'chef/chef_fs/data_handler/data_handler_base'

class Chef
  module ChefFS
    module DataHandler
      class PolicyGroupDataHandler < DataHandlerBase

        def normalize(policy_group, entry)
          defaults = {
            "name" => remove_dot_json(entry.name),
            "policies" => {}
          }
          result = normalize_hash(policy_group, defaults)
          result.delete("uri") # not useful data
          result
        end

        def verify_integrity(object_data, entry, &on_error)
          if object_data["policies"].empty?
            on_error.call("Policy group #{object_data["name"]} does not have any policies in it.")
          end
        end

      end
    end
  end
end
