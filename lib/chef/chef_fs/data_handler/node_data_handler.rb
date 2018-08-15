require "chef/chef_fs/data_handler/data_handler_base"
require "chef/node"

class Chef
  module ChefFS
    module DataHandler
      class NodeDataHandler < DataHandlerBase
        def normalize(node, entry)
          result = normalize_hash(node, {
            "name" => remove_dot_json(entry.name),
            "json_class" => "Chef::Node",
            "chef_type" => "node",
            "chef_environment" => "_default",
            "override" => {},
            "normal" => {},
            "default" => {},
            "automatic" => {},
            "run_list" => [],
          })
          result["run_list"] = normalize_run_list(result["run_list"])
          result
        end

        def preserve_key?(key)
          key == "name"
        end

        def chef_class
          Chef::Node
        end

        # Nodes do not support .rb files
      end
    end
  end
end
