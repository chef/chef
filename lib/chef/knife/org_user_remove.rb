#
# Author:: Marc Paradise (<marc@getchef.com>)
# Copyright:: Copyright (c) Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class Chef
  class Knife
    class OrgUserRemove < Knife
      category "CHEF ORGANIZATION MANAGEMENT"
      banner "knife org user remove ORG_NAME USER_NAME"
      attr_accessor :org_name, :username

      option :force_remove_from_admins,
        long: "--force",
        short: "-f",
        description: "Force removal of user from the organization's admins and billing-admins group."

      deps do
        require "chef/org" unless defined?(Chef::Org)
        require "chef/json_compat" unless defined?(Chef::JSONCompat)
      end

      def run
        @org_name, @username = @name_args

        if !org_name || !username
          ui.fatal "You must specify an ORG_NAME and USER_NAME"
          show_usage
          exit 1
        end

        org = Chef::Org.new(@org_name)

        if config[:force_remove_from_admins]
          if org.actor_delete_would_leave_admins_empty?
            failure_error_message(org_name, username)
            ui.msg <<~EOF
              You ran with --force which force removes the user from the admins and billing-admins groups.
              However, removing #{username} from the admins group would leave it empty, which breaks the org.
              Please add another user to org #{org_name} admins group and try again.
            EOF
            exit 1
          end
          remove_user_from_admin_group(org, org_name, username, "admins")
          remove_user_from_admin_group(org, org_name, username, "billing-admins")
        end

        begin
          org.dissociate_user(@username)
        rescue Net::HTTPServerException => e
          if e.response.code == "404"
            ui.msg "User #{username} is not associated with organization #{org_name}"
            exit 1
          elsif e.response.code == "403"
            body = Chef::JSONCompat.from_json(e.response.body)
            if body.key?("error") && body["error"] == "Please remove #{username} from this organization's admins group before removing him or her from the organization."
              failure_error_message(org_name, username)
              ui.msg <<~EOF
                User #{username} is in the organization's admin group. Removing users from an organization without removing them from the admins group is not allowed.
                Re-run this command with --force to remove this user from the admins prior to removing it from the organization.
              EOF
              exit 1
            else
              raise e
            end
          else
            raise e
          end
        end
      end

      def failure_error_message(org_name, username)
        ui.error "Error removing user #{username} from organization #{org_name}."
      end

      def remove_user_from_admin_group(org, org_name, username, admin_group_string)
        org.remove_user_from_group(admin_group_string, username)
      rescue Net::HTTPServerException => e
        if e.response.code == "404"
          ui.warn <<~EOF
            User #{username} is not in the #{admin_group_string} group for organization #{org_name}.
            You probably don't need to pass --force.
          EOF
        else
          raise e
        end
      end
    end
  end
end
