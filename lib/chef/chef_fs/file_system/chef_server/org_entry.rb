require "chef/chef_fs/file_system/chef_server/rest_list_entry"
require "chef/chef_fs/data_handler/organization_data_handler"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        # /organizations/NAME/org.json
        # Represents the actual data at /organizations/NAME (the full name, etc.)
        class OrgEntry < RestListEntry
          def data_handler
            Chef::ChefFS::DataHandler::OrganizationDataHandler.new
          end

          # /organizations/foo/org.json -> GET /organizations/foo
          def api_path
            parent.api_path
          end

          def display_path
            "/org.json"
          end

          def exists?
            parent.exists?
          end

          def delete(recurse)
            raise Chef::ChefFS::FileSystem::OperationNotAllowedError.new(:delete, self)
          end
        end
      end
    end
  end
end
