require "chef/chef_fs/data_handler/data_handler_base"
require "chef/data_bag_item"

class Chef
  module ChefFS
    module DataHandler
      class DataBagItemDataHandler < DataHandlerBase
        def normalize(data_bag_item, entry)
          # If it's wrapped with raw_data, unwrap it.
          if data_bag_item["json_class"] == "Chef::DataBagItem" && data_bag_item["raw_data"]
            data_bag_item = data_bag_item["raw_data"]
          end
          # chef_type and data_bag come back in PUT and POST results, but we don't
          # use those in knife-essentials.
          normalize_hash(data_bag_item, {
            "id" => remove_dot_json(entry.name),
          })
        end

        def normalize_for_post(data_bag_item, entry)
          if data_bag_item["json_class"] == "Chef::DataBagItem" && data_bag_item["raw_data"]
            data_bag_item = data_bag_item["raw_data"]
          end
          {
            "name" => "data_bag_item_#{entry.parent.name}_#{remove_dot_json(entry.name)}",
            "json_class" => "Chef::DataBagItem",
            "chef_type" => "data_bag_item",
            "data_bag" => entry.parent.name,
            "raw_data" => normalize(data_bag_item, entry),
          }
        end

        def normalize_for_put(data_bag_item, entry)
          normalize_for_post(data_bag_item, entry)
        end

        def preserve_key?(key)
          key == "id"
        end

        def chef_class
          Chef::DataBagItem
        end

        # Verify that the JSON hash for this type has a key that matches its name.
        #
        # @param object [Object] JSON hash of the object
        # @param entry [Chef::ChefFS::FileSystem::BaseFSObject] filesystem object we are verifying
        # @yield  [s] callback to handle errors
        # @yieldparam [s<string>] error message
        def verify_integrity(object, entry)
          base_name = remove_dot_json(entry.name)
          if object["raw_data"]["id"] != base_name
            yield("ID in #{entry.path_for_printing} must be '#{base_name}' (is '#{object['raw_data']['id']}')")
          end
        end

        # Data bags do not support .rb files (or if they do, it's undocumented)
      end
    end
  end
end
