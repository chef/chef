require "chef/chef_fs/data_handler/data_handler_base"
require "chef/role"

class Chef
  module ChefFS
    module DataHandler
      class RoleDataHandler < DataHandlerBase
        def normalize(role, entry)
          result = normalize_hash(role, {
            "name" => remove_file_extension(entry.name),
            "description" => "",
            "json_class" => "Chef::Role",
            "chef_type" => "role",
            "default_attributes" => {},
            "override_attributes" => {},
            "run_list" => [],
            "env_run_lists" => {},
          })
          result["run_list"] = normalize_run_list(result["run_list"])
          result["env_run_lists"].each_pair do |env, run_list|
            result["env_run_lists"][env] = normalize_run_list(run_list)
          end
          result
        end

        def preserve_key?(key)
          key == "name"
        end

        def chef_class
          Chef::Role
        end

        def to_ruby(object)
          to_ruby_keys(object, %w{name description default_attributes override_attributes run_list env_run_lists})
        end
      end
    end
  end
end
