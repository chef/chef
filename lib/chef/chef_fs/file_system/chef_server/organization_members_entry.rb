require "chef/chef_fs/file_system/chef_server/rest_list_entry"
require "chef/chef_fs/data_handler/organization_members_data_handler"
require "chef/json_compat"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        # /organizations/NAME/members.json
        # reads data from:
        # - GET /organizations/NAME/users
        # writes data to:
        # - remove from list: DELETE /organizations/NAME/users/name
        # - add to list: POST /organizations/NAME/users/name
        class OrganizationMembersEntry < RestListEntry
          def initialize(name, parent, exists = nil)
            super(name, parent)
            @exists = exists
          end

          def data_handler
            Chef::ChefFS::DataHandler::OrganizationMembersDataHandler.new
          end

          # /organizations/foo/members.json -> /organizations/foo/users
          def api_path
            File.join(parent.api_path, "users")
          end

          def display_path
            "/members.json"
          end

          def exists?
            parent.exists?
          end

          def delete(recurse)
            raise Chef::ChefFS::FileSystem::OperationNotAllowedError.new(:delete, self)
          end

          def write(contents)
            desired_members = minimize_value(Chef::JSONCompat.parse(contents, :create_additions => false))
            members = minimize_value(_read_json)
            (desired_members - members).each do |member|
              begin
                rest.post(api_path, "username" => member)
              rescue Net::HTTPServerException => e
                if %w{404 405}.include?(e.response.code)
                  raise "Chef server at #{api_path} does not allow you to directly add members.  Please either upgrade your Chef server or move the users you want into invitations.json instead of members.json."
                else
                  raise
                end
              end
            end
            (members - desired_members).each do |member|
              rest.delete(File.join(api_path, member))
            end
          end
        end
      end
    end
  end
end
