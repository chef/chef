#
# Author:: AJ Christensen (<aj@chef.io>)
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
      class Groupadd < Chef::Provider::Group

        def required_binaries
          [ "/usr/sbin/groupadd",
            "/usr/sbin/groupmod",
            "/usr/sbin/groupdel" ]
        end

        def load_current_resource
          super
        end

        def define_resource_requirements
          super
          required_binaries.each do |required_binary|
            requirements.assert(:all_actions) do |a|
              a.assertion { ::File.exist?(required_binary) }
              a.failure_message Chef::Exceptions::Group, "Could not find binary #{required_binary} for #{new_resource}"
              # No whyrun alternative: this component should be available in the base install of any given system that uses it
            end
          end
        end

        # Create the group
        def create_group
          shell_out!("groupadd", set_options, groupadd_options)
          modify_group_members
        end

        # Manage the group when it already exists
        def manage_group
          shell_out!("groupmod", set_options)
          modify_group_members
        end

        # Remove the group
        def remove_group
          shell_out!("groupdel", new_resource.group_name)
        end

        def modify_group_members
          if new_resource.append
            if new_resource.members && !new_resource.members.empty?
              members_to_be_added = [ ]
              new_resource.members.each do |member|
                members_to_be_added << member unless current_resource.members.include?(member)
              end
              members_to_be_added.each do |member|
                logger.debug("#{new_resource} appending member #{member} to group #{new_resource.group_name}")
                add_member(member)
              end
            end

            if new_resource.excluded_members && !new_resource.excluded_members.empty?
              members_to_be_removed = [ ]
              new_resource.excluded_members.each do |member|
                members_to_be_removed << member if current_resource.members.include?(member)
              end

              members_to_be_removed.each do |member|
                logger.debug("#{new_resource} removing member #{member} from group #{new_resource.group_name}")
                remove_member(member)
              end
            end
          else
            members_description = new_resource.members.empty? ? "none" : new_resource.members.join(", ")
            logger.debug("#{new_resource} setting group members to: #{members_description}")
            set_members(new_resource.members)
          end
        end

        def add_member(member)
          raise Chef::Exceptions::Group, "you must override add_member in #{self}"
        end

        def remove_member(member)
          raise Chef::Exceptions::Group, "you must override remove_member in #{self}"
        end

        def set_members(members)
          raise Chef::Exceptions::Group, "you must override set_members in #{self}"
        end

        # Little bit of magic as per Adam's useradd provider to pull the assign the command line flags
        #
        # ==== Returns
        # <string>:: A string containing the option and then the quoted value
        def set_options
          opts = []
          { gid: "-g" }.sort_by { |a| a[0] }.each do |field, option|
            next unless current_resource.send(field) != new_resource.send(field)
            next unless new_resource.send(field)

            opts << option
            opts << new_resource.send(field)
            logger.trace("#{new_resource} set #{field} to #{new_resource.send(field)}")
          end
          opts << new_resource.group_name
          opts
        end

        def groupadd_options
          opts = []
          # Solaris doesn't support system groups.
          opts << "-r" if new_resource.system && !node.platform?("solaris2")
          opts << "-o" if new_resource.non_unique
          opts
        end

      end
    end
  end
end
