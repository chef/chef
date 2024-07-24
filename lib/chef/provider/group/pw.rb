#
# Author:: Stephen Haynes (<sh@nomitor.com>)
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
      class Pw < Chef::Provider::Group
        provides :group, platform: "freebsd"

        def load_current_resource
          super
        end

        def define_resource_requirements
          super

          requirements.assert(:all_actions) do |a|
            a.assertion { ::File.exist?("/usr/sbin/pw") }
            a.failure_message Chef::Exceptions::Group, "Could not find binary /usr/sbin/pw for #{new_resource}"
            # No whyrun alternative: this component should be available in the base install of any given system that uses it
          end
        end

        # Create the group
        def create_group
          command = [ "pw", "groupadd", set_options ]
          unless new_resource.members.empty?
            # pw group[add|mod] -M is used to set the full membership list on a
            # new or existing group. Because pw groupadd does not support the -m
            # and -d options used by manage_group, we treat group creation as a
            # special case and use -M.
            logger.debug("#{new_resource} setting group members: #{new_resource.members.join(",")}")
            command += [ "-M", new_resource.members.join(",") ]
          end

          shell_out!(command)
        end

        # Manage the group when it already exists
        def manage_group
          member_options = set_members_options
          if member_options.empty?
            shell_out!("pw", "groupmod", set_options)
          else
            member_options.each do |option|
              shell_out!("pw", "groupmod", set_options, option)
            end
          end
        end

        # Remove the group
        def remove_group
          shell_out!("pw", "groupdel", new_resource.group_name)
        end

        # Little bit of magic as per Adam's useradd provider to pull and assign the command line flags
        #
        # ==== Returns
        # <string>:: A string containing the option and then the quoted value
        def set_options
          opts = [ new_resource.group_name ]
          if new_resource.gid && (current_resource.gid != new_resource.gid)
            logger.trace("#{new_resource}: current gid (#{current_resource.gid}) doesn't match target gid (#{new_resource.gid}), changing it")
            opts << "-g"
            opts << new_resource.gid
          end
          opts
        end

        # Set the membership option depending on the current resource states
        def set_members_options
          opts = [ ]
          members_to_be_added = [ ]
          members_to_be_removed = [ ]

          if new_resource.append
            # Append is set so we will only add members given in the
            # members list and remove members given in the
            # excluded_members list.
            if new_resource.members && !new_resource.members.empty?
              new_resource.members.each do |member|
                members_to_be_added << member unless current_resource.members.include?(member)
              end
            end

            if new_resource.excluded_members && !new_resource.excluded_members.empty?
              new_resource.excluded_members.each do |member|
                members_to_be_removed << member if current_resource.members.include?(member)
              end
            end
          else
            # Append is not set so we're resetting the membership of
            # the group to the given members.
            members_to_be_added = new_resource.members.dup
            current_resource.members.each do |member|
              # No need to re-add a member if it's present in the new
              # list of members
              if members_to_be_added.include? member
                members_to_be_added.delete member
              else
                members_to_be_removed << member
              end
            end
          end

          unless members_to_be_added.empty?
            logger.debug("#{new_resource} adding group members: #{members_to_be_added.join(",")}")
            opts << [ "-m", members_to_be_added.join(",") ]
          end

          unless members_to_be_removed.empty?
            logger.debug("#{new_resource} removing group members: #{members_to_be_removed.join(",")}")
            opts << [ "-d", members_to_be_removed.join(",") ]
          end

          opts
        end

      end
    end
  end
end
