#
# Author:: AJ Christensen (<aj@chef.io>)
# Copyright:: Copyright 2008-2017, Chef Software Inc.
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

require "chef/provider"
require "chef/mixin/shell_out"
require "etc"

class Chef
  class Provider
    class Group < Chef::Provider
      include Chef::Mixin::ShellOut
      attr_accessor :group_exists
      attr_accessor :change_desc

      def initialize(new_resource, run_context)
        super
        @group_exists = true
      end

      def load_current_resource
        @current_resource = Chef::Resource::Group.new(new_resource.name)
        current_resource.group_name(new_resource.group_name)

        group_info = nil
        begin
          group_info = Etc.getgrnam(new_resource.group_name)
        rescue ArgumentError
          @group_exists = false
          Chef::Log.debug("#{new_resource} group does not exist")
        end

        if group_info
          new_resource.gid(group_info.gid) unless new_resource.gid
          current_resource.gid(group_info.gid)
          current_resource.members(group_info.mem)
        end

        current_resource
      end

      def define_resource_requirements
        requirements.assert(:modify) do |a|
          a.assertion { @group_exists }
          a.failure_message(Chef::Exceptions::Group, "Cannot modify #{new_resource} - group does not exist!")
          a.whyrun("Group #{new_resource} does not exist. Unless it would have been created earlier in this run, this attempt to modify it would fail.")
        end

        requirements.assert(:all_actions) do |a|
          # Make sure that the resource doesn't contain any common
          # user names in the members and exclude_members properties.
          if !new_resource.members.nil? && !new_resource.excluded_members.nil?
            common_members = new_resource.members & new_resource.excluded_members
            a.assertion { common_members.empty? }
            a.failure_message(Chef::Exceptions::ConflictingMembersInGroup, "Attempting to both add and remove users from a group: '#{common_members.join(', ')}'")
            # No why-run alternative
          end
        end
      end

      # Check to see if a group needs any changes. Populate
      # @change_desc with a description of why a change must occur
      #
      # ==== Returns
      # <true>:: If a change is required
      # <false>:: If a change is not required
      def compare_group
        @change_desc = [ ]
        if new_resource.gid.to_s != current_resource.gid.to_s
          @change_desc << "change gid #{current_resource.gid} to #{new_resource.gid}"
        end

        if new_resource.append
          missing_members = []
          new_resource.members.each do |member|
            next if has_current_group_member?(member)
            validate_member!(member)
            missing_members << member
          end
          unless missing_members.empty?
            @change_desc << "add missing member(s): #{missing_members.join(', ')}"
          end

          members_to_be_removed = []
          new_resource.excluded_members.each do |member|
            if has_current_group_member?(member)
              members_to_be_removed << member
            end
          end
          unless members_to_be_removed.empty?
            @change_desc << "remove existing member(s): #{members_to_be_removed.join(', ')}"
          end
        elsif new_resource.members != current_resource.members
          @change_desc << "replace group members with new list of members"
        end

        !@change_desc.empty?
      end

      def has_current_group_member?(member)
        current_resource.members.include?(member)
      end

      def validate_member!(member)
        # Sub-classes can do any validation if needed
        # and raise an error if validation fails
        true
      end

      def action_create
        case @group_exists
        when false
          converge_by("create group #{new_resource.group_name}") do
            create_group
            Chef::Log.info("#{new_resource} created")
          end
        else
          if compare_group
            converge_by(["alter group #{new_resource.group_name}"] + change_desc) do
              manage_group
              Chef::Log.info("#{new_resource} altered")
            end
          end
        end
      end

      def action_remove
        return unless @group_exists
        converge_by("remove group #{new_resource.group_name}") do
          remove_group
          Chef::Log.info("#{new_resource} removed")
        end
      end

      def action_manage
        return unless @group_exists && compare_group
        converge_by(["manage group #{new_resource.group_name}"] + change_desc) do
          manage_group
          Chef::Log.info("#{new_resource} managed")
        end
      end

      def action_modify
        return unless compare_group
        converge_by(["modify group #{new_resource.group_name}"] + change_desc) do
          manage_group
          Chef::Log.info("#{new_resource} modified")
        end
      end

      def create_group
        raise NotImplementedError, "subclasses of Chef::Provider::Group should define #create_group"
      end

      def manage_group
        raise NotImplementedError, "subclasses of Chef::Provider::Group should define #manage_group"
      end

      def remove_group
        raise NotImplementedError, "subclasses of Chef::Provider::Group should define #remove_group"
      end

    end
  end
end
