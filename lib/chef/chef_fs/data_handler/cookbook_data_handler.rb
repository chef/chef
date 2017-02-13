require "chef/chef_fs/data_handler/data_handler_base"
require "chef/cookbook/metadata"

class Chef
  module ChefFS
    module DataHandler
      class CookbookDataHandler < DataHandlerBase
        def normalize(cookbook, entry)
          version = entry.name
          name = entry.parent.name
          result = normalize_hash(cookbook, {
            "name" => "#{name}-#{version}",
            "version" => version,
            "cookbook_name" => name,
            "json_class" => "Chef::CookbookVersion",
            "chef_type" => "cookbook_version",
            "frozen?" => false,
            "metadata" => {},
          })
          result["metadata"] = normalize_hash(result["metadata"], {
            "version" => version,
            "name" => name,
          })
        end

        def preserve_key?(key)
          key == "cookbook_name" || key == "version"
        end

        def chef_class
          Chef::Cookbook::Metadata
        end

        # Not using this yet, so not sure if to_ruby will be useful.
      end
    end
  end
end
