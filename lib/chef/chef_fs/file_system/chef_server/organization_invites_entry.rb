require "chef/chef_fs/file_system/chef_server/rest_list_entry"
require "chef/chef_fs/data_handler/organization_invites_data_handler"
require "chef/json_compat"

class Chef
  module ChefFS
    module FileSystem
      module ChefServer
        # /organizations/NAME/invitations.json
        # read data from:
        # - GET /organizations/NAME/association_requests
        # write data to:
        # - remove from list: DELETE /organizations/NAME/association_requests/id
        # - add to list: POST /organizations/NAME/association_requests
        class OrganizationInvitesEntry < RestListEntry
          def initialize(name, parent, exists = nil)
            super(name, parent)
            @exists = exists
          end

          def data_handler
            Chef::ChefFS::DataHandler::OrganizationInvitesDataHandler.new
          end

          # /organizations/foo/invites.json -> /organizations/foo/association_requests
          def api_path
            File.join(parent.api_path, "association_requests")
          end

          def display_path
            "/invitations.json"
          end

          def exists?
            parent.exists?
          end

          def delete(recurse)
            raise Chef::ChefFS::FileSystem::OperationNotAllowedError.new(:delete, self)
          end

          def write(contents)
            desired_invites = minimize_value(Chef::JSONCompat.parse(contents, :create_additions => false))
            actual_invites = _read_json.inject({}) { |h, val| h[val["username"]] = val["id"]; h }
            invites = actual_invites.keys
            (desired_invites - invites).each do |invite|
              begin
                rest.post(api_path, { "user" => invite })
              rescue Net::HTTPServerException => e
                if e.response.code == "409"
                  Chef::Log.warn("Could not invite #{invite} to organization #{org}: #{api_error_text(e.response)}")
                else
                  raise
                end
              end
            end
            (invites - desired_invites).each do |invite|
              rest.delete(File.join(api_path, actual_invites[invite]))
            end
          end
        end
      end
    end
  end
end
