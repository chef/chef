require "chef/chef_fs/data_handler/data_handler_base"
require "chef/api_client"

class Chef
  module ChefFS
    module DataHandler
      class GroupDataHandler < DataHandlerBase
        def normalize(group, entry)
          defaults = {
            "name" => remove_dot_json(entry.name),
            "groupname" => remove_dot_json(entry.name),
            "users" => [],
            "clients" => [],
            "groups" => [],
          }
          if entry.org
            defaults["orgname"] = entry.org
          end
          result = normalize_hash(group, defaults)
          if result["actors"] && result["actors"].sort.uniq == (result["users"] + result["clients"]).sort.uniq
            result.delete("actors")
          end
          result
        end

        def normalize_for_put(group, entry)
          result = super(group, entry)
          result["actors"] = {
            "users" => result["users"],
            "clients" => result["clients"],
            "groups" => result["groups"],
          }
          result.delete("users")
          result.delete("clients")
          result.delete("groups")
          result
        end

        def normalize_for_post(group, entry)
          normalize_for_put(group, entry)
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
