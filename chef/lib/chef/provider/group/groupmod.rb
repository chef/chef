#
# Author:: Dan Crosta (<dcrosta@late.am>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

require 'chef/mixin/shell_out'

class Chef
  class Provider
    class Group
      class Groupmod < Chef::Provider::Group

        include Chef::Mixin::ShellOut

        def load_current_resource
          super
          [ "group", "user" ].each do |binary|
            raise Chef::Exceptions::Group, "Could not find binary /usr/sbin/#{binary} for #{@new_resource}" unless ::File.exists?("/usr/sbin/#{binary}")
          end
        end

        # Create the group
        def create_group
          command = "group add"
          command << set_options
          shell_out!(command)

          add_group_members(@new_resource.members)
        end

        # Manage the group when it already exists
        def manage_group
          if @new_resource.append
            to_add = @new_resource.members.dup
            to_add.reject! { |user| @current_resource.members.include?(user) }

            to_delete = Array.new

            Chef::Log.debug("#{@new_resource} not changing group members, the group has no members to add") if to_add.empty?
          else
            to_add = @new_resource.members.dup
            to_add.reject! { |user| @current_resource.members.include?(user) }

            to_delete = @current_resource.members.dup
            to_delete.reject! { |user| @new_resource.members.include?(user) }

            Chef::Log.debug("#{@new_resource} setting group members to: none") if @new_resource.members.empty?
          end

          if to_delete.empty?
            # If we are only adding new members to this group, then
            # call add_group_members with only those users
            add_group_members(to_add)
          else
            Chef::Log.debug("#{@new_resource} removing members #{to_delete.join(', ')}")

            # This is tricky, but works: rename the existing group to
            # "<name>_bak", create a new group with the same GID and
            # "<name>", then set correct members on that group
            rename = "group mod -n #{@new_resource.group_name}_bak #{@new_resource.group_name}"
            shell_out!(rename)

            create = "group add"
            create << set_options(:overwrite_gid => true)
            shell_out!(create)

            # Ignore to_add here, since we're replacing the group we
            # have to add all members who should be in the group.
            add_group_members(@new_resource.members)

            remove = "group del #{@new_resource.group_name}_bak"
            shell_out!(remove)
          end
        end

        # Remove the group
        def remove_group
          shell_out!("group del #{@new_resource.group_name}")
        end

        # Adds a list of usernames to the group using `user mod`
        def add_group_members(members)
          Chef::Log.debug("#{@new_resource} adding members #{members.join(', ')}") if !members.empty?
          members.each do |user|
            shell_out!("user mod -G #{@new_resource.group_name} #{user}")
          end
        end

        # Little bit of magic as per Adam's useradd provider to pull and assign the command line flags
        #
        # ==== Returns
        # <string>:: A string containing the option and then the quoted value
        def set_options(overwrite_gid=false)
          opts = ""
          if overwrite_gid || @new_resource.gid && (@current_resource.gid != @new_resource.gid)
            opts << " -g '#{@new_resource.gid}'"
          end
          if overwrite_gid
            opts << " -o"
          end
          opts << " #{@new_resource.group_name}"
          opts
        end
      end
    end
  end
end
