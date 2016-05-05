require "chef/chef_fs/file_system/chef_server/rest_list_entry"
require "chef/chef_fs/data_handler/data_bag_item_data_handler"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        # /policies/NAME-REVISION.json
        # Represents the actual data at /organizations/ORG/policies/NAME/revisions/REVISION
        class DataBagEntry < RestListEntry
          def display_path
            pth = "/data_bags/#{parent.name}/#{name}"
            File.extname(pth).empty? ? pth + ".json" : pth
          end
        end
      end
    end
  end
end
