#
# Author:: Dan Crosta (<dcrosta@late.am>)
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
  class Provider
    class Group
      class Groupmod < Chef::Provider::Group

        provides :group, os: "netbsd"

        def load_current_resource
          super
          %w{group user}.each do |binary|
            raise Chef::Exceptions::Group, "Could not find binary /usr/sbin/#{binary} for #{new_resource}" unless ::File.exist?("/usr/sbin/#{binary}")
          end
        end

        # Create the group
        def create_group
          shell_out!("group", "add", set_options)

          add_group_members(new_resource.members)
        end

        # Manage the group when it already exists
        def manage_group
          if new_resource.append
            members_to_be_added = [ ]
            if new_resource.excluded_members && !new_resource.excluded_members.empty?
              # First find out if any member needs to be removed
              members_to_be_removed = [ ]
              new_resource.excluded_members.each do |member|
                members_to_be_removed << member if current_resource.members.include?(member)
              end

              unless members_to_be_removed.empty?
                # We are using a magic trick to remove the groups.
                reset_group_membership

                # Capture the members we need to add in
                # members_to_be_added to be added later on.
                current_resource.members.each do |member|
                  members_to_be_added << member unless members_to_be_removed.include?(member)
                end
              end
            end

            if new_resource.members && !new_resource.members.empty?
              new_resource.members.each do |member|
                members_to_be_added << member unless current_resource.members.include?(member)
              end
            end

            logger.debug("#{new_resource} not changing group members, the group has no members to add") if members_to_be_added.empty?

            add_group_members(members_to_be_added)
          else
            # We are resetting the members of a group so use the same trick
            reset_group_membership
            logger.debug("#{new_resource} setting group members to: none") if new_resource.members.empty?
            add_group_members(new_resource.members)
          end
        end

        # Remove the group
        def remove_group
          shell_out!("group", "del", new_resource.group_name)
        end

        # Adds a list of usernames to the group using `user mod`
        def add_group_members(members)
          logger.debug("#{new_resource} adding members #{members.join(", ")}") unless members.empty?
          members.each do |user|
            shell_out!("user", "mod", "-G", new_resource.group_name, user)
          end
        end

        # This is tricky, but works: rename the existing group to
        # "<name>_bak", create a new group with the same GID and
        # "<name>", then set correct members on that group
        def reset_group_membership
          shell_out!("group", "mod", "-n", "#{new_resource.group_name}_bak", new_resource.group_name)

          shell_out!("group", "add", set_options(overwrite_gid: true))

          shell_out!("group", "del", "#{new_resource.group_name}_bak")
        end

        # Little bit of magic as per Adam's useradd provider to pull and assign the command line flags
        #
        # ==== Returns
        # <string>:: A string containing the option and then the quoted value
        def set_options(overwrite_gid = false)
          opts = []
          if overwrite_gid || new_resource.gid && (current_resource.gid != new_resource.gid)
            opts << "-g"
            opts << new_resource.gid
          end
          if overwrite_gid
            opts << "-o"
          end
          opts << new_resource.group_name
          opts
        end
      end
    end
  end
end
