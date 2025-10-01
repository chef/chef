#
# Author:: Steven Danna (<steve@chef.io>)
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

require_relative "../knife"

class Chef
  class Knife
    class UserDelete < Knife

      deps do
        require "chef/org" unless defined? Chef::Org
      end

      banner "knife user delete USER (options)"

      option :no_disassociate_user,
        long: "--no-disassociate-user",
        short: "-d",
        description: "Don't disassociate the user first"

      option :remove_from_admin_groups,
        long:  "--remove-from-admin-groups",
        short:  "-R",
        description: "If the user is a member of any org admin groups, attempt to remove from those groups. Ignored if --no-disassociate-user is set."

      attr_reader :username

      def run
        @username = @name_args[0]
        admin_memberships = []
        unremovable_memberships = []

        if @username.nil?
          show_usage
          ui.fatal("You must specify a user name")
          exit 1
        end

        ui.confirm "Do you want to delete the user #{username}"

        unless config[:no_disassociate_user]
          ui.stderr.puts("Checking organization memberships...")
          orgs = org_memberships(username)
          if orgs.length > 0
            ui.stderr.puts("Checking admin group memberships for #{orgs.length} org(s).")
            admin_memberships, unremovable_memberships = admin_group_memberships(orgs, username)
          end

          unless admin_memberships.empty?
            unless config[:remove_from_admin_groups]
              error_exit_admin_group_member!(username, admin_memberships)
            end

            unless unremovable_memberships.empty?
              error_exit_cant_remove_admin_membership!(username, unremovable_memberships)
            end
            remove_from_admin_groups(admin_memberships, username)
          end
          disassociate_user(orgs, username)
        end

        delete_user(username)
      end

      def disassociate_user(orgs, username)
        orgs.each  { |org| org.dissociate_user(username) }
      end

      def org_memberships(username)
        org_data = root_rest.get("users/#{username}/organizations")
        org_data.map { |org| Chef::Org.new(org["organization"]["name"]) }
      end

      def remove_from_admin_groups(admin_of, username)
        admin_of.each do |org|
          ui.stderr.puts "Removing #{username} from admins group of '#{org.name}'"
          org.remove_user_from_group("admins", username)
        end
      end

      def admin_group_memberships(orgs, username)
        admin_of = []
        unremovable = []
        orgs.each do |org|
          if org.user_member_of_group?(username, "admins")
            admin_of << org
            if org.actor_delete_would_leave_admins_empty?
              unremovable << org
            end
          end
        end
        [admin_of, unremovable]
      end

      def delete_user(username)
        ui.stderr.puts "Deleting user #{username}."
        root_rest.delete("users/#{username}")
      end

      # Error message that says how to removed from org
      # admin groups before deleting
      # Further
      def error_exit_admin_group_member!(username, admin_of)
        message = "#{username} is in the 'admins' group of the following organization(s):\n\n"
        admin_of.each { |org| message << "- #{org.name}\n" }
        message << <<~EOM

          Run this command again with the --remove-from-admin-groups option to
          remove the user from these admin group(s) automatically.

        EOM
        ui.fatal message
        exit 1
      end

      def error_exit_cant_remove_admin_membership!(username, only_admin_of)
        message = <<~EOM

          #{username} is the only member of the 'admins' group of the
          following organization(s):

        EOM
        only_admin_of.each { |org| message << "- #{org.name}\n" }
        message << <<~EOM

          Removing the only administrator of an organization can break it.
          Assign additional users or groups to the admin group(s) before
          deleting this user.

        EOM
        ui.fatal message
        exit 1
      end
    end
  end
end
