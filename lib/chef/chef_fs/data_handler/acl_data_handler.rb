require "chef/chef_fs/data_handler/data_handler_base"

class Chef
  module ChefFS
    module DataHandler
      class AclDataHandler < DataHandlerBase
        def normalize(acl, entry)
          # Normalize the order of the keys for easier reading
          result = normalize_hash(acl, {
            "create" => {},
            "read" => {},
            "update" => {},
            "delete" => {},
            "grant" => {},
            })
          result.keys.each do |key|
            result[key] = normalize_hash(result[key], { "actors" => [], "groups" => [] })
            result[key]["actors"] = result[key]["actors"].sort
            result[key]["groups"] = result[key]["groups"].sort
          end
          result
        end
      end
    end
  end
end
