require "chef/chef_fs/data_handler/data_handler_base"
require "chef/api_client"

class Chef
  module ChefFS
    module DataHandler
      class ClientDataHandler < DataHandlerBase
        def normalize(client, entry)
          defaults = {
            "name" => remove_dot_json(entry.name),
            "clientname" => remove_dot_json(entry.name),
            "admin" => false,
            "validator" => false,
            "chef_type" => "client",
          }
          # Handle the fact that admin/validator have changed type from string -> boolean
          client["admin"] = (client["admin"] == "true") if client["admin"].is_a?(String)
          client["validator"] = (client["validator"] == "true") if client["validator"].is_a?(String)
          if entry.respond_to?(:org) && entry.org
            defaults["orgname"] = entry.org
          end
          result = normalize_hash(client, defaults)
          result.delete("json_class")
          result
        end

        def preserve_key?(key)
          key == "name"
        end

        def chef_class
          Chef::ApiClient
        end

        # There is no Ruby API for Chef::ApiClient
      end
    end
  end
end
