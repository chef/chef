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

class Chef
  class Provider
    class Group
      class Groupmod < Chef::Provider::Group

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
          run_command(:command => command)

          add_group_members(@new_resource.members)
        end

        # Manage the group when it already exists
        def manage_group
          current_members = get_group_members

          # Create an array of current members who
          # should be removed from the group, that
          # is, if they are not in the resource's
          # members array
          to_delete = Array.new(current_members)
          to_delete.reject! { |user| @new_resource.members.include?(user) }

          # Now create an array of members specified
          # in the resource but not yet present in
          # the current_members.
          to_add = Array.new(@new_resource.members)
          to_add.reject! { |user| current_members.include?(user) }

          if !to_delete.empty?
            # This is tricky, but works: rename the existing
            # group to "<name>_bak", create a new group with
            # the same GID and "<name>", then set correct
            # members on that group
            rename = "group mod -n #{@new_resource.group_name}_bak #{@new_resource.group_name}"
            run_command(:command => rename)

            create = "group add"
            create << set_options(:overwrite_gid => true)
            run_command(:command => create)

            add_group_members(@new_resource.members)

            remove = "group del #{@new_resource.group_name}_bak"
            run_command(:command => remove)
          else
            # If we are only adding new members to this group,
            # then call add_group_members with only those users
            add_group_members(to_add)
          end
        end

        # Remove the group
        def remove_group
          run_command(:command => "group del #{@new_resource.group_name}")
        end

        # Adds a list of usernames to the group using `user mod`
        def add_group_members(members)
          members.each do |user|
            command = "user mod -G #{@new_resource.group_name} #{user}"
            run_command(:command => command)
          end
        end

        # Little bit of magic as per Adam's useradd provider to pull and assign the command line flags
        #
        # ==== Returns
        # <string>:: A string containing the option and then the quoted value
        def set_options(overwrite_gid=false)
          opts = ""
          if overwrite_gid || @new_resource.gid && (@current_resource.gid != @new_resource.gid)
            Chef::Log.debug("#{@new_resource}: current gid (#{@current_resource.gid}) doesnt match target gid (#{@new_resource.gid}), changing it")
            opts << " -g '#{@new_resource.gid}'"
          end
          if overwrite_gid
            opts << " -o"
          end
          opts << " #{@new_resource.group_name}"
          opts
        end

        # Parse the output of "group info <groupanme>" to determine the members
        def get_group_members
          command = "group info #{@new_resource.group_name}"
          status, stdout, stderr = output_of_command(command, {})

          raise Chef::Exceptions::Group, "#{command} returned status #{status}, expected 0" if status != 0

          members = /members\s+([\w, ]+)$/m.match(stdout)[1]
          members.split(/, +/)
        end
      end
    end
  end
end
